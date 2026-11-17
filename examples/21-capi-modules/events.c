// build: module
// events.c: keeping Lua values alive from C (registry references) and
// C closures with private state (upvalues)
#include "../20-capi-embed/lua_compat.h"

/* events.on(fn) -> id: store a callback; C cannot keep a pointer to a Lua
 * function, so it keeps an integer reference into the registry instead */
static int ev_on(lua_State *L) {
  luaL_checktype(L, 1, LUA_TFUNCTION);
  lua_settop(L, 1);
  int ref = luaL_ref(L, LUA_REGISTRYINDEX);       /* pops the function */
  /* remember the ref: upvalue 1 is an array of refs in registration order */
  lua_pushinteger(L, ref);
  lua_rawseti(L, lua_upvalueindex(1), (int)lua_rawlen(L, lua_upvalueindex(1)) + 1);
  lua_pushinteger(L, ref);
  return 1;
}

/* events.off(id) -> found: release the reference so the function can be collected */
static int ev_off(lua_State *L) {
  int ref = (int)luaL_checkinteger(L, 1);
  int list = lua_upvalueindex(1), n = (int)lua_rawlen(L, list), found = 0;
  for (int i = 1; i <= n; i++) {                  /* remove it, shifting the rest down */
    lua_rawgeti(L, list, i);
    if (!found && lua_tointeger(L, -1) == ref) found = 1;
    lua_pop(L, 1);
    if (found) { lua_rawgeti(L, list, i + 1); lua_rawseti(L, list, i); }
  }
  if (found) luaL_unref(L, LUA_REGISTRYINDEX, ref);
  lua_pushboolean(L, found);
  return 1;
}

/* events.emit(...): call every callback with the arguments, in id order */
static int ev_emit(lua_State *L) {
  int nargs = lua_gettop(L), calls = 0;
  int n = (int)lua_rawlen(L, lua_upvalueindex(1));
  for (int i = 1; i <= n; i++) {
    lua_rawgeti(L, lua_upvalueindex(1), i);
    int ref = (int)lua_tointeger(L, -1);
    lua_pop(L, 1);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ref);       /* fetch the function back */
    for (int i = 1; i <= nargs; i++) lua_pushvalue(L, i);
    lua_call(L, nargs, 0);                        /* errors propagate to the caller */
    calls++;
  }
  lua_pushinteger(L, calls);
  return 1;
}

/* events.counter(start) -> function: each call returns the next number.
 * The count lives in upvalue 1 of the C closure, private to that closure. */
static int counter_step(lua_State *L) {
  lua_Integer n = lua_tointeger(L, lua_upvalueindex(1)) + 1;
  lua_pushinteger(L, n);
  lua_replace(L, lua_upvalueindex(1));            /* update the upvalue */
  lua_pushinteger(L, n);
  return 1;
}
static int ev_counter(lua_State *L) {
  lua_pushinteger(L, luaL_optinteger(L, 1, 0));
  lua_pushcclosure(L, counter_step, 1);
  return 1;
}

/* events.tag(): light userdata are bare pointers, compared by address */
static int ev_tag(lua_State *L) {
  static const char tag;
  lua_pushlightuserdata(L, (void *)&tag);
  return 1;
}

int luaopen_events(lua_State *L) {
  static const luaL_Reg with_list[] = {
    { "on", ev_on }, { "off", ev_off }, { "emit", ev_emit }, { NULL, NULL }
  };
  lua_newtable(L);                                /* module table */
  lua_newtable(L);                                /* shared upvalue: the list */
  luaL_setfuncs(L, with_list, 1);                 /* all three share upvalue 1 */
  lua_pushcfunction(L, ev_counter); lua_setfield(L, -2, "counter");
  lua_pushcfunction(L, ev_tag); lua_setfield(L, -2, "tag");
  return 1;
}
