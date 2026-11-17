// build: exe
// stack.c: the virtual stack - every value C and Lua exchange goes through it
#include <stdio.h>
#include "lua_compat.h"

static void dump(lua_State *L, const char *label) {
  int top = lua_gettop(L);
  printf("%-26s [", label);
  for (int i = 1; i <= top; i++) {
    int t = lua_type(L, i);
    switch (t) {
      case LUA_TNUMBER:
        if (lua_isinteger(L, i)) printf("%lld", (long long)lua_tointeger(L, i));
        else printf("%.14g", lua_tonumber(L, i));
        break;
      case LUA_TSTRING:  printf("'%s'", lua_tostring(L, i)); break;
      case LUA_TBOOLEAN: printf(lua_toboolean(L, i) ? "true" : "false"); break;
      default:           printf("%s", lua_typename(L, t)); break;
    }
    if (i < top) printf(", ");
  }
  printf("]  top=%d\n", top);
}

int main(void) {
  lua_State *L = luaL_newstate();
  lua_pushinteger(L, 42);                       /* index 1, or -4 */
  lua_pushnumber(L, 2.5);                       /* index 2, or -3 */
  lua_pushstring(L, "frame");                   /* index 3, or -2 */
  lua_pushboolean(L, 1);                        /* index 4, or -1 */
  dump(L, "pushed 4 values");
  printf("index -1 is a %s, index 1 is a %s\n",
         luaL_typename(L, -1), luaL_typename(L, 1));

  lua_pushvalue(L, 1);  dump(L, "pushvalue(1)");   /* copy to the top */
  lua_insert(L, 2);     dump(L, "insert(2)");      /* move top into slot 2 */
  lua_remove(L, 1);     dump(L, "remove(1)");
  lua_pushnil(L);
  lua_replace(L, 1);    dump(L, "pushnil + replace(1)");
  lua_settop(L, 2);     dump(L, "settop(2)");      /* drop the rest */
  lua_newtable(L);      dump(L, "newtable");
  lua_settop(L, 0);     dump(L, "settop(0)");

  /* conversions: lua_tonumber/lua_tostring convert in place, like Lua does */
  lua_pushstring(L, "0x10");
  printf("'0x10' as number: %.14g\n", lua_tonumber(L, -1));
  lua_pushinteger(L, 7);
  const char *seven = lua_tostring(L, -1);      /* the slot now holds a string! */
  printf("7 as string: %s, and now it is a %s\n", seven, luaL_typename(L, -1));
  lua_close(L);
  return 0;
}
