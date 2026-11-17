// build: exe
// Exercise 2 solution: stop a runaway script with an instruction-count hook
#include <stdio.h>
#include "lua_compat.h"
#if LUA_VERSION_NUM == 501                /* assume LuaJIT */
#include <luajit.h>
#endif

static long budget;
static void count_hook(lua_State *L, lua_Debug *ar) {
  (void)ar;
  budget -= 1000;
  if (budget <= 0) luaL_error(L, "instruction budget exceeded");
}

static void run_limited(lua_State *L, const char *code, long instructions) {
  budget = instructions;
  lua_sethook(L, count_hook, LUA_MASKCOUNT, 1000);   /* every 1000 VM instructions */
  int st = luaL_dostring(L, code);
  lua_sethook(L, NULL, 0, 0);
  printf("%s\n", st == LUA_OK ? "finished" : lua_tostring(L, -1));
  lua_settop(L, 0);
}

int main(void) {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
#if LUA_VERSION_NUM == 501
  /* Hooks are not called from JIT-compiled code: without this line LuaJIT
   * compiles the infinite loop and the hook stops firing. */
  luaJIT_setmode(L, 0, LUAJIT_MODE_ENGINE | LUAJIT_MODE_OFF);
#endif
  run_limited(L, "local s = 0 for i = 1, 1000 do s = s + i end", 1000000);
  run_limited(L, "while true do end", 1000000);
  lua_close(L);
  return 0;
}
