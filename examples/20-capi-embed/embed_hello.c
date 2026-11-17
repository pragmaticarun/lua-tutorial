// build: exe
// embed_hello.c: the smallest useful embedding of Lua in a C program
#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main(void) {
  lua_State *L = luaL_newstate();          /* a new, independent interpreter */
  if (L == NULL) return 1;
  luaL_openlibs(L);                        /* string, table, math, io, os, ... */

  printf("compiled against: %s (LUA_VERSION_NUM %d)\n", LUA_RELEASE, LUA_VERSION_NUM);

  /* run a chunk; luaL_dostring = luaL_loadstring + lua_pcall */
  if (luaL_dostring(L, "greeting = ('hello from %s'):format(_VERSION)\n"
                       "print(greeting)") != 0) {
    fprintf(stderr, "error: %s\n", lua_tostring(L, -1));
    lua_close(L);
    return 1;
  }

  lua_getglobal(L, "greeting");            /* push the global onto the stack */
  printf("C read back: %s\n", lua_tostring(L, -1));
  lua_pop(L, 1);                           /* keep the stack balanced */

  lua_close(L);                            /* frees everything, runs finalizers */
  return 0;
}
