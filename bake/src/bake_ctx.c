#include "core_set.h"
#include "core_map.h"

#include "bake_ctx.h"

typedef struct _scope_t
{
	set_t idents;
} scope_t;

static map_t s_vars; // TODO: unused..
static vec_t s_scopes;
static vec_t s_exprs;
static vec_t s_expr_stack;
static vec_t s_elif_stack;

void ctx_push_exprs(void)
{
	vec_t exprs = vec_alloc(sizeof(expr_t));
	vec_push(&s_expr_stack, &exprs);
}
void ctx_push_expr(expr_t expr)
{
	vec_t* exprs = (vec_t*)vec_back(&s_expr_stack);
	vec_push(exprs, &expr);
}
vec_t ctx_pop_exprs(void)
{
	vec_t exprs;
	vec_pop(&s_expr_stack, &exprs);
	return exprs;
}
void ctx_push_elifs(void)
{
	vec_t elifs = vec_alloc(sizeof(expr_t));
	vec_push(&s_elif_stack, &elifs);
}
void ctx_push_elif(expr_t elif)
{
	vec_t* elifs = (vec_t*)vec_back(&s_elif_stack);
	vec_push(elifs, &elif);
}
vec_t ctx_pop_elifs(void)
{
	vec_t elifs;
	vec_pop(&s_elif_stack, &elifs);
	return elifs;
}
void ctx_push_scope(void)
{
	scope_t scope;
	memset(&scope, 0, sizeof(scope_t));
	scope.idents = set_alloc();
	vec_push(&s_scopes, &scope);
}
void ctx_pop_scope(void)
{
	scope_t scope;
	vec_pop(&s_scopes, &scope);
	set_free(&scope.idents);
}
void ctx_alloc(void)
{
	s_vars = map_alloc();
	s_scopes = vec_alloc(sizeof(scope_t));
	s_exprs = vec_alloc(sizeof(expr_t));
	s_expr_stack = vec_alloc(sizeof(vec_t));
	s_elif_stack = vec_alloc(sizeof(vec_t));
}
void ctx_push_global(expr_t expr)
{
	vec_push(&s_exprs, &expr);
}
str_t ctx_insert_ident(str_t ident)
{
	// TODO: check all idents up till root scope..
	scope_t* scope = (scope_t*)vec_back(&s_scopes);
	if (set_contains(&scope->idents, str_buffer(&ident), str_size(&ident)))
	{
		yyerror("duplicate identifier <%s>", str_buffer(&ident));
	}
	else
	{
		set_insert(&scope->idents, str_buffer(&ident), str_size(&ident));
	}
	return ident;
}
void ctx_remove_ident(str_t ident)
{
	scope_t* scope = (scope_t*)vec_back(&s_scopes);
	if (set_remove(&scope->idents, str_buffer(&ident), str_size(&ident)))
	{

	}
	else
	{
		yyerror("undefined identifier <%s>", ident.buffer);
	}
}
str_t ctx_validate_ident(str_t ident)
{
	uint64_t scope_index = 0;
	uint64_t scope_count = vec_count(&s_scopes);
	while (scope_index < scope_count)
	{
		scope_t* scope = (scope_t*)vec_at(&s_scopes, scope_count - scope_index - 1);
		if (set_contains(&scope->idents, str_buffer(&ident), str_size(&ident)))
		{
			return ident;
		}
		scope_index++;
	}
	yyerror("undefined identifier %s", str_buffer(&ident));
	return ident;
}
void ctx_insert_var(str_t ident, str_t value)
{
	map_insert(&s_vars, str_buffer(&ident), str_size(&ident), str_buffer(&value), str_size(&value));
}
str_t* ctx_get_var(str_t ident)
{
	return map_at(&s_vars, str_buffer(&ident), str_size(&ident));
}
void ctx_build(char const* rule_name)
{
	//uint64_t expr_index = 0;
	//uint64_t expr_count = vec_count(&s_exprs);
	//while (expr_index < expr_count)
	//{
	//	expr_t* expr = (expr_t*)vec_at(&s_exprs, expr_index);
	//	expr_build(expr);
	//	expr_index++;
	//}
}
void ctx_print(void)
{
	uint64_t expr_index = 0;
	uint64_t expr_count = vec_count(&s_exprs);
	while (expr_index < expr_count)
	{
		expr_t expr = *(expr_t*)vec_at(&s_exprs, expr_index);
		expr_print(expr, 0, 2, 1, expr_index == 0, expr_index == (expr_count - 1));
		expr_index++;
	}
}
void ctx_free(void)
{
	uint64_t expr_index = 0;
	uint64_t expr_count = vec_count(&s_exprs);
	while (expr_index < expr_count)
	{
		expr_t expr = *(expr_t*)vec_at(&s_exprs, expr_index);
		expr_free(expr);
		expr_index++;
	}
	map_free(&s_vars);
	vec_free(&s_scopes);
	vec_free(&s_exprs);
	vec_free(&s_expr_stack);
	vec_free(&s_elif_stack);
}
