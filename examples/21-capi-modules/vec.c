// build: module
// vec.c: a C module with a userdata type, loadable with require("vec")
//   gcc -O2 -shared -fPIC -I<lua include dir> -o vec.so vec.c
#include <math.h>
#include "../20-capi-embed/lua_compat.h"

#define VEC_MT "tutorial.Vec2"          /* registry key of the metatable */

typedef struct { double x, y; } Vec2;

static Vec2 *push_vec(lua_State *L, double x, double y) {
  Vec2 *v = (Vec2 *)lua_newuserdata(L, sizeof(Vec2));   /* memory owned by Lua */
  v->x = x; v->y = y;
  luaL_setmetatable(L, VEC_MT);
  return v;
}
static Vec2 *check_vec(lua_State *L, int i) {
  return (Vec2 *)luaL_checkudata(L, i, VEC_MT);         /* type-checked cast */
}

static int vec_new(lua_State *L) {
  push_vec(L, luaL_optnumber(L, 1, 0), luaL_optnumber(L, 2, 0));
  return 1;
}
static int vec_add(lua_State *L) {
  Vec2 *a = check_vec(L, 1), *b = check_vec(L, 2);
  push_vec(L, a->x + b->x, a->y + b->y);
  return 1;
}
static int vec_eq(lua_State *L) {
  Vec2 *a = check_vec(L, 1), *b = check_vec(L, 2);
  lua_pushboolean(L, a->x == b->x && a->y == b->y);
  return 1;
}
static int vec_tostring(lua_State *L) {
  Vec2 *v = check_vec(L, 1);
  lua_pushfstring(L, "Vec2(%f, %f)", v->x, v->y);
  return 1;
}
static int vec_len(lua_State *L) {
  Vec2 *v = check_vec(L, 1);
  lua_pushnumber(L, sqrt(v->x * v->x + v->y * v->y));
  return 1;
}
static int vec_unpack(lua_State *L) {
  Vec2 *v = check_vec(L, 1);
  lua_pushnumber(L, v->x); lua_pushnumber(L, v->y);
  return 2;
}

static const luaL_Reg vec_meta[] = {
  { "__add", vec_add }, { "__eq", vec_eq }, { "__tostring", vec_tostring },
  { NULL, NULL }
};
static const luaL_Reg vec_methods[] = {
  { "len", vec_len }, { "unpack", vec_unpack }, { NULL, NULL }
};
static const luaL_Reg vec_funcs[] = { { "new", vec_new }, { NULL, NULL } };

/* the entry point: require("vec") calls luaopen_vec */
int luaopen_vec(lua_State *L) {
  if (luaL_newmetatable(L, VEC_MT)) {         /* 0 if it already existed */
    luaL_setfuncs(L, vec_meta, 0);
    luaL_newlib(L, vec_methods);              /* metatable.__index = methods */
    lua_setfield(L, -2, "__index");
  }
  lua_pop(L, 1);
  luaL_newlib(L, vec_funcs);                  /* the module table */
  return 1;
}
