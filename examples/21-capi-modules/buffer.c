// build: module
// buffer.c: a userdata that owns a C resource (malloc'd memory), released by
// close(), by <close> (__close, Lua 5.4+) or, as a last resort, by __gc
#include <stdlib.h>
#include <string.h>
#include "../20-capi-embed/lua_compat.h"

#define BUF_MT "tutorial.Buffer"

typedef struct {
  unsigned char *data;      /* NULL once released */
  size_t size;
} Buffer;

/* per-state statistics, stored in the registry under a light userdata key:
 * the address of a static variable is unique, so it cannot clash with the
 * keys of other modules */
static const char STATS_KEY = 'k';

static void count(lua_State *L, const char *field, int delta) {
  lua_rawgetp(L, LUA_REGISTRYINDEX, &STATS_KEY);
  compat_getfield(L, -1, field);
  lua_pushinteger(L, lua_tointeger(L, -1) + delta);
  lua_setfield(L, -3, field);
  lua_pop(L, 2);
}

static Buffer *check_open(lua_State *L) {
  Buffer *b = (Buffer *)luaL_checkudata(L, 1, BUF_MT);
  if (b->data == NULL) luaL_error(L, "buffer is closed");
  return b;
}

static void release(lua_State *L, Buffer *b, const char *how) {
  if (b->data == NULL) return;                    /* idempotent */
  free(b->data); b->data = NULL;
  count(L, "live", -1);
  count(L, how, 1);
}

static int buf_new(lua_State *L) {
  lua_Integer n = luaL_checkinteger(L, 1);
  luaL_argcheck(L, n > 0, 1, "size must be positive");
  Buffer *b = (Buffer *)lua_newuserdata(L, sizeof(Buffer));
  b->data = NULL; b->size = 0;                    /* safe state before anything can fail */
  luaL_setmetatable(L, BUF_MT);
  b->data = (unsigned char *)calloc((size_t)n, 1);
  if (b->data == NULL) return luaL_error(L, "out of memory");
  b->size = (size_t)n;
  count(L, "live", 1);
  return 1;
}
static int buf_fill(lua_State *L) {
  Buffer *b = check_open(L);
  memset(b->data, (int)luaL_checkinteger(L, 2) & 0xff, b->size);
  lua_settop(L, 1);
  return 1;                                       /* return self for chaining */
}
static int buf_sum(lua_State *L) {
  Buffer *b = check_open(L);
  lua_Integer s = 0;
  for (size_t i = 0; i < b->size; i++) s += b->data[i];
  lua_pushinteger(L, s);
  return 1;
}
static int buf_len(lua_State *L) {
  Buffer *b = (Buffer *)luaL_checkudata(L, 1, BUF_MT);
  lua_pushinteger(L, (lua_Integer)(b->data ? b->size : 0));
  return 1;
}
static int buf_close(lua_State *L) {
  release(L, (Buffer *)luaL_checkudata(L, 1, BUF_MT), "closed");
  return 0;
}
static int buf_gc(lua_State *L) {
  release(L, (Buffer *)luaL_checkudata(L, 1, BUF_MT), "collected");
  return 0;
}
static int buf_stats(lua_State *L) {
  lua_rawgetp(L, LUA_REGISTRYINDEX, &STATS_KEY);
  const char *fields[] = { "live", "closed", "collected", NULL };
  for (int i = 0; fields[i]; i++) compat_getfield(L, -1 - i, fields[i]);
  return 3;
}

static const luaL_Reg buf_meta[] = {
  { "__gc", buf_gc }, { "__len", buf_len }, { "__close", buf_close }, { NULL, NULL }
};
static const luaL_Reg buf_methods[] = {
  { "fill", buf_fill }, { "sum", buf_sum }, { "close", buf_close }, { NULL, NULL }
};
static const luaL_Reg buf_funcs[] = { { "new", buf_new }, { "stats", buf_stats }, { NULL, NULL } };

int luaopen_buffer(lua_State *L) {
  lua_newtable(L);                                /* statistics table */
  lua_pushinteger(L, 0); lua_setfield(L, -2, "live");
  lua_pushinteger(L, 0); lua_setfield(L, -2, "closed");
  lua_pushinteger(L, 0); lua_setfield(L, -2, "collected");
  lua_rawsetp(L, LUA_REGISTRYINDEX, &STATS_KEY);

  luaL_newmetatable(L, BUF_MT);
  luaL_setfuncs(L, buf_meta, 0);   /* __close is simply ignored before Lua 5.4 */
  luaL_newlib(L, buf_methods);
  lua_setfield(L, -2, "__index");
  lua_pop(L, 1);
  luaL_newlib(L, buf_funcs);
  return 1;
}
