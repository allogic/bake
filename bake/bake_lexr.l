%x MULTI_LINE_COMMENT

%{
#include "bake_pasr.h"

#ifndef UPDATE_CURSOR_LOCATION_SINGLE_LINE
	#define UPDATE_CURSOR_LOCATION_SINGLE_LINE() \
		yylloc.first_line = g_line_number; \
		yylloc.first_column = g_column_number; \
		g_column_number += yyleng; \
		yylloc.last_line = g_line_number; \
		yylloc.last_column = g_column_number - 1
#endif // UPDATE_CURSOR_LOCATION_SINGLE_LINE

#ifndef UPDATE_CURSOR_LOCATION_MULTI_LINE
	#define UPDATE_CURSOR_LOCATION_MULTI_LINE() \
		yylloc.first_line = g_line_number; \
		yylloc.first_column = g_column_number; \
		{ \
			char const* ptr = yytext; \
			while (*ptr) \
			{ \
				if (*ptr == '\r') \
				{ \
					g_column_number = 1; \
				} \
				else if (*ptr == '\n') \
				{ \
					g_line_number++; \
				} \
				else \
				{ \
					g_column_number++; \
				} \
				ptr++; \
			} \
		} \
		yylloc.last_line = g_line_number; \
		yylloc.last_column = g_column_number
#endif // UPDATE_CURSOR_LOCATION_MULTI_LINE

#ifndef UPDATE_CURSOR_LOCATION_CARRIAGE_RETURN
	#define UPDATE_CURSOR_LOCATION_CARRIAGE_RETURN() \
		yylloc.first_line = g_line_number; \
		yylloc.first_column = g_column_number; \
		g_column_number = 1; \
		yylloc.last_line = g_line_number; \
		yylloc.last_column = g_column_number
#endif // UPDATE_CURSOR_LOCATION_CARRIAGE_RETURN

#ifndef UPDATE_CURSOR_LOCATION_NEW_LINE
	#define UPDATE_CURSOR_LOCATION_NEW_LINE() \
		yylloc.first_line = g_line_number; \
		yylloc.first_column = g_column_number; \
		g_line_number++; \
		yylloc.last_line = g_line_number; \
		yylloc.last_column = g_column_number
#endif // UPDATE_CURSOR_LOCATION_NEW_LINE
%}

%%
"mkdir" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return MKDIR;
}

"mkfile" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return MKFILE;
}

"rmdir" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return RMDIR;
}

"rmfile" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return RMFILE;
}

"printf" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return PRINTF;
}

"shell" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return SHELL;
}

"if" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return IF;
}

"else" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return ELSE;
}

"," {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return COMMA;
}

"=" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return EQUALS;
}

"+=" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return PEQ;
}

"-=" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return MEQ;
}

"?=" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return QEQ;
}

"==" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return EQEQ;
}

":" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return COLON;
}

";" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return SEMICOLON;
}

"(" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return LPAREN;
}

")" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return RPAREN;
}

"{" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return LBRACE;
}

"}" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	return RBRACE;
}

"\r" {
	UPDATE_CURSOR_LOCATION_CARRIAGE_RETURN();
}

"\n" {
	UPDATE_CURSOR_LOCATION_NEW_LINE();
}

[\t ] {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
}

"//"[^\r\n]* {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
}

"/*" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	BEGIN(MULTI_LINE_COMMENT);
}

<MULTI_LINE_COMMENT>"\r" {
	UPDATE_CURSOR_LOCATION_CARRIAGE_RETURN();
}

<MULTI_LINE_COMMENT>"\n" {
	UPDATE_CURSOR_LOCATION_NEW_LINE();
}

<MULTI_LINE_COMMENT>. {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
}

<MULTI_LINE_COMMENT>"*/" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	BEGIN(INITIAL);
}

[a-zA-Z_][a-zA-Z0-9_]* {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	yylval.string = str_from(yytext);
	return IDENT;
}

"\""[^"]*"\"" {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
	yylval.string = str_from(yytext);
	return STRING;
}

. {
	UPDATE_CURSOR_LOCATION_SINGLE_LINE();
}
%%
