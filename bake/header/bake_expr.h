#ifndef BAKE_EXPR_H
#define BAKE_EXPR_H

#include <stdint.h>

#include "core_str.h"
#include "core_vec.h"

typedef enum _expr_type_t
{
	EXPR_TYPE_NONE = 0,
	EXPR_TYPE_PACK,
	EXPR_TYPE_RULE,
	EXPR_TYPE_CALL,
	EXPR_TYPE_VAR,
	EXPR_TYPE_IF,
	EXPR_TYPE_COPY,
	EXPR_TYPE_COPY_ADD,
	EXPR_TYPE_COPY_IF,
	EXPR_TYPE_IDENT,
	EXPR_TYPE_STRING,
	EXPR_TYPE_COND,
	EXPR_TYPE_COMP,
	EXPR_TYPE_IF_BLOCK,
	EXPR_TYPE_IF_ELSE_BLOCK,
	EXPR_TYPE_MKDIR,
	EXPR_TYPE_MKFILE,
	EXPR_TYPE_RMDIR,
	EXPR_TYPE_RMFILE,
	EXPR_TYPE_PRINTF,
	EXPR_TYPE_SHELL
} expr_type_t;

typedef enum _expr_alloc_t
{
	EXPR_ALLOC_IDENT = 0x1,
	EXPR_ALLOC_STRING = 0x2,
	EXPR_ALLOC_EXPRS = 0x4
} expr_alloc_t;

typedef struct _expr_t
{
	expr_type_t type;
	expr_alloc_t alloc;
	str_t ident;
	str_t string;
	vec_t exprs;
} expr_t;

extern expr_t expr_none(void);
extern expr_t expr_packi(uint64_t expr_count, ...);
extern expr_t expr_packv(vec_t exprs);
extern expr_t expr_rule(expr_t pattern, expr_t depend, expr_t scope);
extern expr_t expr_call(expr_t expr);
extern expr_t expr_var(expr_t expr);
extern expr_t expr_if(expr_t expr);
extern expr_t expr_copy(expr_t left, expr_t right);
extern expr_t expr_copy_add(expr_t left, expr_t right);
extern expr_t expr_copy_if(expr_t left, expr_t right);
extern expr_t expr_cond(expr_t expr);
extern expr_t expr_comp(expr_t left, expr_t right);
extern expr_t expr_ident(str_t ident);
extern expr_t expr_string(str_t string);
extern expr_t expr_cond(expr_t expr);
extern expr_t expr_if_block(expr_t pack);
extern expr_t expr_if_else_block(expr_t pack);
extern expr_t expr_mkdir(expr_t expr);
extern expr_t expr_mkfile(expr_t expr);
extern expr_t expr_rmdir(expr_t expr);
extern expr_t expr_rmfile(expr_t expr);
extern expr_t expr_printf(expr_t expr);
extern expr_t expr_shell(expr_t expr);

extern void expr_build(expr_t expr);
extern void expr_print(expr_t expr, uint64_t indent_count, uint64_t indent_increment, uint8_t is_global, uint8_t is_first, uint8_t is_last);
extern void expr_free(expr_t expr);

#endif // BAKE_EXPR_H
