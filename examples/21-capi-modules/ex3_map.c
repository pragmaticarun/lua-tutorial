// build: module
// Exercise 3 solution: calling back into Lua from a C function
#include "../20-capi-embed/lua_compat.h"

/* map(t, f) -> new table with f(v, i) for every array element */
static int l_map(lua_State *L) {
  luaL_checktype(L, 1, LUA_TTABLE);
  luaL_checktype(L, 2, LUA_TFUNCTION);
  int n = (int)lua_rawlen(L, 1);
  lua_createtable(L, n, 0);                       /* result at index 3 */
  for (int i = 1; i <= n; i++) {
    lua_pushvalue(L, 2);                          /* f */
    lua_rawgeti(L, 1, i);                         /* v */
    lua_pushinteger(L, i);                        /* i */
    lua_call(L, 2, 1);                            /* unprotected: errors propagate */
    lua_rawseti(L, 3, i);
  }
  return 1;
}

/* try_map(t, f) -> true, result | false, message: catches errors with lua_pcall */
static int l_try_map(lua_State *L) {
  lua_settop(L, 2);
  lua_pushcfunction(L, l_map);
  lua_insert(L, 1);                               /* map, t, f */
  if (lua_pcall(L, 2, 1, 0) != LUA_OK) {
    lua_pushboolean(L, 0);
    lua_insert(L, -2);                            /* false, message */
    return 2;
  }
  lua_pushboolean(L, 1);
  lua_insert(L, -2);                              /* true, result */
  return 2;
}

int luaopen_ex3_map(lua_State *L) {
  static const luaL_Reg f[] = { { "map", l_map }, { "try_map", l_try_map }, { NULL, NULL } };
  luaL_newlib(L, f);
  return 1;
}
