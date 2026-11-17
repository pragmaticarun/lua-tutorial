/* lua_compat.h: the few C API differences between Lua 5.5, 5.4 and LuaJIT
 * (5.1 API + extensions) that the examples in Lessons 20 and 21 need.
 * Real projects often use the "lua-compat-5.3" project for a complete set. */
#ifndef LUA_COMPAT_H
#define LUA_COMPAT_H

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#if LUA_VERSION_NUM == 501                    /* LuaJIT and Lua 5.1 */
#define lua_rawlen(L, i) lua_objlen(L, (i))
#define lua_pushglobaltable(L) lua_pushvalue(L, LUA_GLOBALSINDEX)
#define LUA_OK 0
static inline int lua_absindex(lua_State *L, int i) {
  return (i > 0 || i <= LUA_REGISTRYINDEX) ? i : lua_gettop(L) + i + 1;
}
static inline void lua_rawsetp(lua_State *L, int t, const void *p) {
  t = lua_absindex(L, t);
  lua_pushlightuserdata(L, (void *)p);
  lua_insert(L, -2);
  lua_rawset(L, t);
}
static inline int lua_rawgetp(lua_State *L, int t, const void *p) {
  t = lua_absindex(L, t);
  lua_pushlightuserdata(L, (void *)p);
  lua_rawget(L, t);
  return lua_type(L, -1);
}
/* 5.3+ lua_getfield/lua_getglobal return the type of the pushed value */
static inline int compat_getfield(lua_State *L, int t, const char *k) {
  lua_getfield(L, t, k);
  return lua_type(L, -1);
}
static inline int compat_getglobal(lua_State *L, const char *name) {
  lua_getglobal(L, name);
  return lua_type(L, -1);
}
#define lua_isinteger(L, i) 0                 /* only doubles in LuaJIT */
#else
#define compat_getfield lua_getfield
#define compat_getglobal lua_getglobal
#endif

#if LUA_VERSION_NUM >= 505                    /* 5.5: lua_newstate takes a seed */
#define compat_newstate(alloc, ud) lua_newstate((alloc), (ud), luaL_makeseed(NULL))
#else
#define compat_newstate(alloc, ud) lua_newstate((alloc), (ud))
#endif

#endif
