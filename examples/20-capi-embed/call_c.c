// build: exe
// call_c.c: exposing C functions to Lua scripts
#include <stdio.h>
#include <string.h>
#include "lua_compat.h"

/* clamp(x, lo, hi): arguments arrive on the stack at 1..n */
static int l_clamp(lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_Number lo = luaL_optnumber(L, 2, 0.0);
  lua_Number hi = luaL_optnumber(L, 3, 1.0);
  luaL_argcheck(L, lo <= hi, 3, "upper bound below lower bound");
  lua_pushnumber(L, x < lo ? lo : (x > hi ? hi : x));
  return 1;                                     /* number of results */
}

/* split(s, sep) -> table of fields */
static int l_split(lua_State *L) {
  size_t len, seplen;
  const char *s = luaL_checklstring(L, 1, &len);
  const char *sep = luaL_checklstring(L, 2, &seplen);
  if (seplen == 0) return luaL_error(L, "empty separator");
  lua_newtable(L);
  int n = 0;
  const char *start = s, *end = s + len, *hit;
  while ((hit = strstr(start, sep)) != NULL) {
    lua_pushlstring(L, start, (size_t)(hit - start));
    lua_rawseti(L, -2, ++n);
    start = hit + seplen;
  }
  lua_pushlstring(L, start, (size_t)(end - start));
  lua_rawseti(L, -2, ++n);
  return 1;
}

/* minmax(...) -> min, max, count : any number of arguments and results */
static int l_minmax(lua_State *L) {
  int n = lua_gettop(L);
  if (n == 0) return 0;
  lua_Number mn = luaL_checknumber(L, 1), mx = mn;
  for (int i = 2; i <= n; i++) {
    lua_Number v = luaL_checknumber(L, i);
    if (v < mn) mn = v;
    if (v > mx) mx = v;
  }
  lua_pushnumber(L, mn); lua_pushnumber(L, mx); lua_pushinteger(L, n);
  return 3;
}

static const luaL_Reg util_funcs[] = {
  { "clamp", l_clamp }, { "split", l_split }, { "minmax", l_minmax }, { NULL, NULL }
};

int main(void) {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  lua_register(L, "clamp", l_clamp);            /* one global function */
  luaL_newlib(L, util_funcs);                   /* or a table of functions */
  lua_setglobal(L, "util");

  const char *script =
    "print(clamp(1.5), clamp(-3, -1, 1), util.clamp(0.25))\n"
    "print(table.concat(util.split('a,b,,c', ','), '|'), #util.split('', ','))\n"
    "print(util.minmax(3, 9, -2, 7))\n"
    "print(pcall(util.clamp, 'x'))\n"
    "print(pcall(util.clamp, 1, 2, 1))\n"
    "print(pcall(util.split, 'a', ''))\n";
  if (luaL_dostring(L, script) != LUA_OK) printf("error: %s\n", lua_tostring(L, -1));
  lua_close(L);
  return 0;
}
