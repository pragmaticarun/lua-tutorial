// build: exe
// call_lua.c: load a Lua configuration file and call Lua functions from C
#include <stdio.h>
#include "lua_compat.h"

static int get_int_field(lua_State *L, int t, const char *key, int fallback) {
  int value = fallback;
  if (compat_getfield(L, t, key) == LUA_TNUMBER) value = (int)lua_tointeger(L, -1);
  lua_pop(L, 1);
  return value;
}

int main(void) {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  if (luaL_dofile(L, "config.lua") != LUA_OK) {
    fprintf(stderr, "config error: %s\n", lua_tostring(L, -1));
    return 1;
  }

  /* read a table */
  if (compat_getglobal(L, "output") != LUA_TTABLE) { fprintf(stderr, "no output\n"); return 1; }
  int w = get_int_field(L, -1, "width", 640);
  int h = get_int_field(L, -1, "height", 480);
  int fps = get_int_field(L, -1, "fps", 30);           /* missing: use default */
  compat_getfield(L, -1, "codec");
  printf("output: %dx%d @ %d fps, codec %s\n", w, h, fps, lua_tostring(L, -1));
  lua_pop(L, 2);                                        /* codec, output */

  /* iterate an array */
  compat_getglobal(L, "presets");
  int n = (int)lua_rawlen(L, -1);
  for (int i = 1; i <= n; i++) {
    lua_rawgeti(L, -1, i);
    printf("preset %d: %s\n", i, lua_tostring(L, -1));
    lua_pop(L, 1);
  }
  lua_pop(L, 1);

  /* call a function: push function, push args, lua_pcall(nargs, nresults, msgh) */
  for (int frame = 0; frame < 3; frame++) {
    compat_getglobal(L, "on_frame");
    lua_pushinteger(L, frame - 1);
    lua_pushnumber(L, frame / 25.0);
    if (lua_pcall(L, 2, 2, 0) != LUA_OK) {
      printf("on_frame(%d) failed: %s\n", frame - 1, lua_tostring(L, -1));
      lua_pop(L, 1);
      continue;
    }
    printf("on_frame(%d) -> %s, %.0f ms\n", frame - 1, lua_tostring(L, -2), lua_tonumber(L, -1));
    lua_pop(L, 2);
  }
  printf("stack top at exit: %d\n", lua_gettop(L));
  lua_close(L);
  return 0;
}
