#ifndef BAKE_CTX_H
#define BAKE_CTX_H

#include <stdint.h>

#include "core_str.h"
#include "core_vec.h"

#include "bake_config.h"
#include "bake_expr.h"

extern void ctx_push_exprs(void);
extern void ctx_push_expr(expr_t expr);
extern vec_t ctx_pop_exprs(void);

extern void ctx_push_elifs(void);
extern void ctx_push_elif(expr_t elif);
extern vec_t ctx_pop_elifs(void);

extern void ctx_push_scope(void);
extern void ctx_pop_scope(void);

extern void ctx_alloc(void);
extern void ctx_push_global(expr_t expr);
extern str_t ctx_insert_ident(str_t ident);
extern void ctx_remove_ident(str_t ident);
extern str_t ctx_validate_ident(str_t ident);
extern void ctx_insert_var(str_t ident, str_t value);
extern str_t* ctx_get_var(str_t ident);
extern void ctx_build(char const* target_name);
extern void ctx_print(void);
extern void ctx_free(void);

#endif // BAKE_CTX_H
