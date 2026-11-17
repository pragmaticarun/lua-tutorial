// build: module
// Exercise 2 solution: a userdata that references a Lua table (its user value)
#include "../20-capi-embed/lua_compat.h"

#define NODE_MT "tutorial.Node"
typedef struct { int id; } Node;

/* Lua 5.4+: numbered user values; Lua 5.1/LuaJIT: the userdata environment */
static void set_uservalue(lua_State *L, int ud) {
#if LUA_VERSION_NUM >= 504
  lua_setiuservalue(L, ud, 1);
#else
  lua_setfenv(L, ud);
#endif
}
static void get_uservalue(lua_State *L, int ud) {
#if LUA_VERSION_NUM >= 504
  lua_getiuservalue(L, ud, 1);
#else
  lua_getfenv(L, ud);
#endif
}

static int node_new(lua_State *L) {
  int id = (int)luaL_checkinteger(L, 1);
  luaL_checktype(L, 2, LUA_TTABLE);                 /* attached metadata */
  Node *n = (Node *)lua_newuserdata(L, sizeof(Node));   /* 5.4+: one user value */
  n->id = id;
  luaL_setmetatable(L, NODE_MT);
  lua_pushvalue(L, 2);
  set_uservalue(L, -2);               /* the userdata keeps the table alive */
  return 1;
}
static int node_index(lua_State *L) {               /* node.id or node.<meta field> */
  Node *n = (Node *)luaL_checkudata(L, 1, NODE_MT);
  const char *k = luaL_checkstring(L, 2);
  if (k[0] == 'i' && k[1] == 'd' && k[2] == 0) { lua_pushinteger(L, n->id); return 1; }
  get_uservalue(L, 1);
  lua_getfield(L, -1, k);
  return 1;
}

int luaopen_ex2_node(lua_State *L) {
  luaL_newmetatable(L, NODE_MT);
  lua_pushcfunction(L, node_index);
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1);
  lua_newtable(L);
  lua_pushcfunction(L, node_new);
  lua_setfield(L, -2, "new");
  return 1;
}
