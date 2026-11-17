// build: exe
// Exercise 1 solution: run an untrusted chunk with a restricted environment
#include <stdio.h>
#include <string.h>
#include "lua_compat.h"

static void run_sandboxed(lua_State *L, const char *code) {
  if (luaL_loadbuffer(L, code, strlen(code), "=untrusted") != LUA_OK) {
    printf("load error: %s\n", lua_tostring(L, -1)); lua_pop(L, 1); return;
  }
  /* the environment: only what we copy in */
  lua_newtable(L);
  const char *allowed[] = { "print", "math", "string", "tostring", "type", NULL };
  for (int i = 0; allowed[i]; i++) {
    lua_getglobal(L, allowed[i]);
    lua_setfield(L, -2, allowed[i]);
  }
#if LUA_VERSION_NUM >= 502
  /* a main chunk's first upvalue is _ENV */
  lua_setupvalue(L, -2, 1);
#else
  /* Lua 5.1 / LuaJIT: function environments */
  lua_setfenv(L, -2);
#endif
  if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
    printf("runtime error: %s\n", lua_tostring(L, -1)); lua_pop(L, 1);
  }
}

int main(void) {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  run_sandboxed(L, "print(math.max(3, 7), ('ok'):upper(), type(os), type(io), type(require))");
  run_sandboxed(L, "os.execute('echo pwned')");
  run_sandboxed(L, "leak = 'set by script'");
  lua_getglobal(L, "leak");                 /* the real globals were not touched */
  printf("global leak in host state: %s\n", lua_isnil(L, -1) ? "nil" : lua_tostring(L, -1));
  lua_close(L);
  return 0;
}
