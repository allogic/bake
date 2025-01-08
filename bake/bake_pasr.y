%define parse.assert
%define parse.error verbose

%locations

%code requires
{
#ifdef _WIN32
	#define fileno _fileno
	#define isatty _isatty
#endif // _WIN32

	#include <stdint.h>
	#include <stdarg.h>

	#include "core_heap.h"
	#include "core_str.h"
	#include "core_vec.h"
	#include "core_timer.h"

	#include "bake_ctx.h"
	#include "bake_expr.h"
	#include "bake_log.h"

	extern int32_t yyerror(char const* msg, ...);
	extern int32_t yywrap(void);

	extern char const* g_current_filename;
	extern char* yytext;
	extern int32_t g_line_number;
	extern int32_t g_column_number;
	extern int32_t yyleng;
}

%token MKDIR
%token MKFILE
%token RMDIR
%token RMFILE
%token PRINTF
%token SHELL
%token IF
%token ELSE
%token IDENT
%token STRING
%token COMMA
%token EQUALS
%token PEQ
%token MEQ
%token QEQ
%token EQEQ
%token COLON
%token SEMICOLON
%token LPAREN
%token RPAREN
%token LBRACE
%token RBRACE

%union
{
	str_t string;
	expr_t expr;
}

%type <string> IDENT
%type <string> STRING
%type <expr> TARGET
%type <expr> DEPEND
%type <expr> EXPR
%type <expr> STMT
%type <expr> CALL_STMT
%type <expr> VAR_STMT
%type <expr> IF_STMT
%type <expr> CONDITION
%type <expr> COMPARISON

%nonassoc IFX // TODO
%nonassoc ELSE

%%
PROGRAM
	: PROGRAM STMT { ctx_push_global($2); }
	| PROGRAM TARGET { ctx_push_global($2); }
	| PROGRAM RULE { /* TODO */ }
	| %empty
	;

TARGET
	: IDENT LPAREN DEPEND_LIST_BEGIN RPAREN LBRACE STMT_LIST_BEGIN RBRACE
		{
			expr_t ident = expr_ident(ctx_insert_ident($1));
			expr_t body_pack = expr_packv(ctx_pop_exprs());
			expr_t depend_pack = expr_packv(ctx_pop_exprs());
			$$ = expr_target(ident, depend_pack, body_pack);
		}
	;

RULE
	: STRING LPAREN DEPEND_LIST_BEGIN RPAREN LBRACE STMT_LIST_BEGIN RBRACE
		{
			// TODO
		}
	;

DEPEND_LIST_BEGIN
	: { ctx_push_exprs(); } DEPEND_LIST
	;

DEPEND_LIST
	: DEPEND COMMA DEPEND_LIST { ctx_push_expr($1); }
	| DEPEND { ctx_push_expr($1); }
	| %empty
	;

DEPEND
	: IDENT { $$ = expr_ident(ctx_validate_ident($1)); }
	;

STMT_LIST_BEGIN
	: { ctx_push_exprs(); } STMT_LIST
	;

STMT_LIST
	: STMT_LIST STMT { ctx_push_expr($2); }
	| %empty
	;

STMT
	: CALL_STMT { $$ = expr_call($1); }
	| VAR_STMT { $$ = expr_var($1); }
	| IF_STMT { $$ = expr_if($1); }
	;

// %prec IFX

IF_STMT
	: IF LPAREN CONDITION RPAREN LBRACE STMT_LIST_BEGIN RBRACE
		{
			expr_t if_pack = expr_packv(ctx_pop_exprs());
			expr_t pack = expr_packi(2, $3, if_pack);
			$$ = expr_if_block(pack);
		}
	| IF LPAREN CONDITION RPAREN LBRACE STMT_LIST_BEGIN RBRACE ELSE LBRACE STMT_LIST_BEGIN RBRACE
		{
			expr_t else_pack = expr_packv(ctx_pop_exprs());
			expr_t if_pack = expr_packv(ctx_pop_exprs());
			expr_t pack = expr_packi(3, $3, if_pack, else_pack);
			$$ = expr_if_else_block(pack);
		}
	| IF LPAREN CONDITION RPAREN LBRACE STMT_LIST_BEGIN RBRACE ELIF_LIST
		{
			expr_t elif_pack = expr_packv(ctx_pop_elifs());
			expr_t if_pack = expr_packv(ctx_pop_exprs());
			expr_t pack = expr_packi(3, $3, if_pack, elif_pack);
			$$ = expr_if_elif_block(pack);
		}
	| IF LPAREN CONDITION RPAREN LBRACE STMT_LIST_BEGIN RBRACE ELIF_LIST %prec ELSE LBRACE STMT_LIST_BEGIN RBRACE
		{
			expr_t else_pack = expr_packv(ctx_pop_exprs());
			expr_t elif_pack = expr_packv(ctx_pop_elifs());
			expr_t if_pack = expr_packv(ctx_pop_exprs());
			expr_t pack = expr_packi(4, $3, if_pack, elif_pack, else_pack);
			$$ = expr_if_elif_else_block(pack);
		}
	;

// TODO: make like depend..
ELIF_LIST
	: ELIF_LIST { ctx_push_elifs(); } ELSE IF LPAREN CONDITION RPAREN LBRACE STMT_LIST_BEGIN RBRACE
		{
			expr_t elif_pack = expr_packv(ctx_pop_exprs());
			expr_t pack = expr_packi(2, $6, elif_pack);
			ctx_push_elif(pack);
		}
	| /* { ctx_push_elifs(); } */ ELSE IF LPAREN CONDITION RPAREN LBRACE STMT_LIST_BEGIN RBRACE
		{
			expr_t elif_pack = expr_packv(ctx_pop_exprs());
			expr_t pack = expr_packi(2, $4, elif_pack);
			ctx_push_elif(pack);
		}
	;

VAR_STMT
	: IDENT EQUALS EXPR SEMICOLON { $$ = expr_copy(expr_ident(ctx_insert_ident($1)), $3); }
	| IDENT PEQ EXPR SEMICOLON { $$ = expr_copy_add(expr_ident(ctx_validate_ident($1)), $3); }
	| IDENT QEQ STRING SEMICOLON { $$ = expr_copy_if(expr_ident(ctx_insert_ident($1)), expr_string($3)); }
	;

CALL_STMT
	: MKDIR LPAREN EXPR RPAREN SEMICOLON { $$ = expr_mkdir($3); }
	| MKFILE LPAREN EXPR RPAREN SEMICOLON { $$ = expr_mkfile($3); }
	| RMDIR LPAREN EXPR RPAREN SEMICOLON { $$ = expr_rmdir($3); }
	| RMFILE LPAREN EXPR RPAREN SEMICOLON { $$ = expr_rmfile($3); }
	| PRINTF LPAREN EXPR RPAREN SEMICOLON { $$ = expr_printf($3); }
	| SHELL LPAREN EXPR RPAREN SEMICOLON { $$ = expr_shell($3); }
	;

EXPR
	: IDENT { $$ = expr_ident(ctx_validate_ident($1)); }
	| STRING { $$ = expr_string($1); }
	;

CONDITION
	: COMPARISON { $$ = expr_cond($1); }
	;

COMPARISON
	: EXPR EQEQ EXPR { $$ = expr_comp($1, $3); }
	;
%%

char const* g_current_filename;
int32_t g_line_number;
int32_t g_column_number;

int32_t main(int32_t argc, char** argv)
{
	log_prologue();
	heap_prologue();
	g_current_filename = argv[1];
	g_line_number = 1;
	g_column_number = 1;
	FILE* file = fopen(argv[1], "r"); // TODO: remove this..
	if (file)
	{
		ctx_alloc();
		ctx_push_scope();
#ifdef _DEBUG
		TIMER_BEGIN();
#endif // _DEBUG
		yyrestart(file);
		yyparse();
		//ctx_build("uga"); // TODO
#ifdef _DEBUG
		TIMER_END();
		ctx_print();
#endif // _DEBUG
		ctx_pop_scope();
		ctx_free();
		fclose(file);
	}
	heap_epilogue();
	log_printf("DONE\n"); // TODO
	log_epilogue();
	return 0;
}
int32_t yyerror(char const* msg, ...)
{
	va_list args;
	va_start(args, msg);
	log_printf("%s:%d:%d: %s\n", g_current_filename, yylloc.first_line, yylloc.first_column, msg, args);
	va_end(args);
	return 0;
}
int32_t yywrap(void)
{
	return 1;
}
