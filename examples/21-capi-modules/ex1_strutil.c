// build: module
// Exercise 1 solution: a small string module in C
#include <string.h>
#include "../20-capi-embed/lua_compat.h"

static int is_space(char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r'; }

static int su_trim(lua_State *L) {
  size_t n;
  const char *s = luaL_checklstring(L, 1, &n);
  size_t a = 0, b = n;
  while (a < b && is_space(s[a])) a++;
  while (b > a && is_space(s[b - 1])) b--;
  lua_pushlstring(L, s + a, b - a);       /* Lua strings may contain '\0': use lengths */
  return 1;
}
static int su_startswith(lua_State *L) {
  size_t n, m;
  const char *s = luaL_checklstring(L, 1, &n);
  const char *p = luaL_checklstring(L, 2, &m);
  lua_pushboolean(L, m <= n && memcmp(s, p, m) == 0);
  return 1;
}
static int su_count(lua_State *L) {
  size_t n, m;
  const char *s = luaL_checklstring(L, 1, &n);
  const char *c = luaL_checklstring(L, 2, &m);
  luaL_argcheck(L, m == 1, 2, "single character expected");
  lua_Integer k = 0;
  for (size_t i = 0; i < n; i++) if (s[i] == c[0]) k++;
  lua_pushinteger(L, k);
  return 1;
}

int luaopen_ex1_strutil(lua_State *L) {
  static const luaL_Reg f[] = {
    { "trim", su_trim }, { "startswith", su_startswith }, { "count", su_count }, { NULL, NULL }
  };
  luaL_newlib(L, f);
  return 1;
}
