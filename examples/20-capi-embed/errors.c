// build: exe
// errors.c: lua_pcall status codes, tracebacks, error objects, memory limits
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lua_compat.h"

static const char *status_name(int status) {
  switch (status) {
    case LUA_OK: return "LUA_OK";
    case LUA_ERRRUN: return "LUA_ERRRUN";
    case LUA_ERRSYNTAX: return "LUA_ERRSYNTAX";
    case LUA_ERRMEM: return "LUA_ERRMEM";
    case LUA_ERRERR: return "LUA_ERRERR";
    default: return "other";
  }
}

/* message handler: runs at the error point, before the stack unwinds */
static int traceback(lua_State *L) {
  const char *msg = lua_tostring(L, 1);
  if (msg == NULL) return 1;                    /* keep non-string error objects */
  luaL_traceback(L, L, msg, 1);
  return 1;
}

static void run(lua_State *L, const char *label, const char *code) {
  int base = lua_gettop(L);
  lua_pushcfunction(L, traceback);
  int status = luaL_loadbuffer(L, code, strlen(code), "=script");
  if (status == LUA_OK) status = lua_pcall(L, 0, 0, base + 1);
  printf("-- %s: %s\n", label, status_name(status));
  if (status != LUA_OK) {
    if (lua_type(L, -1) == LUA_TTABLE) {        /* a structured error object */
      compat_getfield(L, -1, "code");
      compat_getfield(L, -2, "msg");
      printf("error object: code=%d msg=%s\n", (int)lua_tointeger(L, -2), lua_tostring(L, -1));
    } else {
      /* print only the first two lines of the traceback */
      const char *s = lua_tostring(L, -1);
      const char *nl = strchr(s, '\n');
      if (nl) nl = strchr(nl + 1, '\n');
      printf("%.*s\n", nl ? (int)(nl - s) : (int)strlen(s), s);
    }
  }
  lua_settop(L, base);                          /* drop handler and error */
}

/* an allocator that refuses to go above a limit: sandboxing memory use */
typedef struct { size_t used, limit; } budget_t;
static void *limited_alloc(void *ud, void *ptr, size_t osize, size_t nsize) {
  budget_t *b = ud;
  if (ptr == NULL) osize = 0;                   /* osize encodes the type then */
  if (nsize == 0) { free(ptr); b->used -= osize; return NULL; }
  if (nsize > osize && b->used + (nsize - osize) > b->limit) return NULL;
  void *p = realloc(ptr, nsize);
  if (p) b->used = b->used - osize + nsize;
  return p;
}

int main(void) {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  run(L, "ok", "local x = 1 + 1");
  run(L, "syntax", "local x = = 1");
  run(L, "runtime", "local function f() local t = nil; return t.x end\nf()");
  run(L, "error object", "error({ code = 404, msg = 'no such stream' })");
  lua_close(L);

  budget_t budget = { 0, 512 * 1024 };
  L = compat_newstate(limited_alloc, &budget);
  if (L == NULL) { printf("custom allocator not supported here\n"); return 0; }
  luaL_openlibs(L);
  run(L, "memory", "local t = {} for i = 1, 1e7 do t[i] = ('x'):rep(64) .. i end");
  printf("usable right away: %s\n", luaL_dostring(L, "return 1") == LUA_OK ? "yes" : "no");
  lua_settop(L, 0);
  lua_gc(L, LUA_GCCOLLECT, 0);                  /* free the half-built table */
  printf("after a full GC: %s\n", luaL_dostring(L, "return 1") == LUA_OK ? "yes" : "no");
  lua_close(L);
  return 0;
}
