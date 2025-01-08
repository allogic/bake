%define parse.assert
%define parse.error verbose

%start PROGRAM

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

	extern int32_t yyerror(char const* msg, ...);
	extern int32_t yywrap(void);

	extern char const* g_current_filename;
	extern char* yytext;
	extern int32_t g_line_number;
	extern int32_t g_column_number;
	extern int32_t yyleng;
}

%token MKDIR MKFILE RMDIR RMFILE PRINTF SHELL
%token IF ELSE
%token IDENT STRING
%token COMMA
%token EQ PEQ MEQ QEQ EQEQ
%token COLON SEMICOLON
%token LPAREN RPAREN
%token LBRACE RBRACE

%union
{
	str_t string;
	expr_t expr;
}

%type <string> IDENT STRING
%type <expr> RULE_DECL DEPEND_PACK STMT_PACK STMT_OR_SCOPE STMT SCOPE IF_STMT VAR_DECL CALL_DECL EXPR COND COMP

%nonassoc RPAREN
%nonassoc ELSE

%%
PROGRAM
	: PROGRAM RULE_DECL { ctx_push_global($2); }
	| PROGRAM STMT { ctx_push_global($2); }
	| %empty
	;

RULE_DECL
	: STRING COLON DEPEND_PACK SCOPE
		{
			$$ = expr_rule(expr_string($1), $3, $4); // TODO: add to rules.. (compare depends for ident)
		}
	;

DEPEND_PACK
	: { ctx_push_exprs(); } LPAREN DEPEND_LIST RPAREN { $$ = expr_packv(ctx_pop_exprs()); }
	;

DEPEND_LIST
	: STRING COMMA DEPEND_LIST { ctx_push_expr(expr_string($1)); }
	| STRING { ctx_push_expr(expr_string($1)); }
	| %empty
	;

STMT_OR_SCOPE
	: STMT { ctx_push_expr($1); $$ = $1; }
	| SCOPE { $$ = $1; }
	;

STMT_PACK
	: { ctx_push_exprs(); } STMT_LIST { $$ = expr_packv(ctx_pop_exprs()); }
	;

STMT_LIST
	: STMT_LIST STMT_OR_SCOPE
	| %empty
	;

STMT
	: IF_STMT { $$ = expr_if($1); }
	| VAR_DECL { $$ = expr_var($1); }
	| CALL_DECL { $$ = expr_call($1); }
	;

SCOPE
	: { ctx_push_scope(); } LBRACE STMT_PACK RBRACE { ctx_pop_scope(); $$ = $3; }
	;

IF_STMT
	: IF LPAREN COND RPAREN STMT_OR_SCOPE ELSE STMT_OR_SCOPE
		{
			$$ = expr_if_else_block(expr_packi(3, $3, $5, $7));
		}
	| IF LPAREN COND RPAREN STMT_OR_SCOPE
		{
			$$ = expr_if_block(expr_packi(2, $3, $5));
		}
	;

VAR_DECL
	: IDENT EQ EXPR SEMICOLON { $$ = expr_copy(expr_ident(ctx_insert_ident($1)), $3); }
	| IDENT PEQ EXPR SEMICOLON { $$ = expr_copy_add(expr_ident(ctx_validate_ident($1)), $3); }
	| IDENT QEQ STRING SEMICOLON { $$ = expr_copy_if(expr_ident(ctx_insert_ident($1)), expr_string($3)); }
	;

CALL_DECL
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

COND
	: COMP { $$ = expr_cond($1); }
	;

COMP
	: EXPR EQEQ EXPR { $$ = expr_comp($1, $3); }
	;
%%

#define LOG_FMT_BUFFER_SIZE (0x1000)

char const* g_current_filename;
int32_t g_line_number;
int32_t g_column_number;

int32_t main(int32_t argc, char** argv)
{
	heap_prologue();
	g_current_filename = argv[1];
	g_line_number = 1;
	g_column_number = 1;
	FILE* file = fopen(argv[1], "r");
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
	printf("DONE\n");
	return 0;
}
int32_t yyerror(char const* fmt, ...)
{
	static char fmt_buffer[LOG_FMT_BUFFER_SIZE];
	va_list args;
	va_start(args, fmt);
	vsnprintf(fmt_buffer, LOG_FMT_BUFFER_SIZE, fmt, args);
	printf("%s:%d:%d: %s\n", g_current_filename, yylloc.first_line, yylloc.first_column, fmt_buffer);
	va_end(args);
	return 1;
}
int32_t yywrap(void)
{
	return 1;
}
