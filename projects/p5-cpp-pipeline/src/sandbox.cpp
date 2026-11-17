#include "sandbox.hpp"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <sstream>

#if defined(__has_include)
#if __has_include(<luajit.h>)
#include <luajit.h>
#endif
#endif

#ifndef LUA_OK
#define LUA_OK 0                            // Lua 5.1 / LuaJIT
#endif

namespace {
const char *const kFrameMeta = "mediapipe.Frame";
const int kHookEvery = 1000;                // the count hook runs every 1000 instructions

// The userdata a script sees. It points at the host's frame only while
// process() runs; afterwards ptr is cleared, so a script that kept the
// frame in a global gets an error instead of a dangling pointer.
struct FrameRef { Frame *ptr; };

Frame &check_frame(lua_State *L) {
  auto *ref = static_cast<FrameRef *>(luaL_checkudata(L, 1, kFrameMeta));
  if (!ref->ptr) luaL_error(L, "frame used after process() returned");
  return *ref->ptr;
}

int coord(lua_State *L, int arg, int limit, const char *what) {
  // luaL_checknumber + floor behaves the same on 5.1 and 5.4+ (checkinteger
  // would reject 1.5 on 5.4+ but truncate it on LuaJIT)
  double v = luaL_checknumber(L, arg);
  int i = static_cast<int>(v);
  if (v < 0 || i >= limit) luaL_error(L, "%s %d out of range 0..%d", what, i, limit - 1);
  return i;
}

int frame_get(lua_State *L) {
  Frame &f = check_frame(L);
  lua_pushinteger(L, f.at(coord(L, 2, f.width, "x"), coord(L, 3, f.height, "y")));
  return 1;
}

int frame_set(lua_State *L) {
  Frame &f = check_frame(L);
  int x = coord(L, 2, f.width, "x"), y = coord(L, 3, f.height, "y");
  double v = luaL_checknumber(L, 4);
  f.at(x, y) = static_cast<std::uint8_t>(v < 0 ? 0 : v > 255 ? 255 : v + 0.5);   // clamp, round
  return 0;
}

int frame_index(lua_State *L) {             // __index: width, height, then methods
  Frame &f = check_frame(L);
  const char *key = luaL_checkstring(L, 2);
  if (std::strcmp(key, "width") == 0) { lua_pushinteger(L, f.width); return 1; }
  if (std::strcmp(key, "height") == 0) { lua_pushinteger(L, f.height); return 1; }
  luaL_getmetatable(L, kFrameMeta);
  lua_getfield(L, -1, "methods");
  lua_getfield(L, -1, key);
  return 1;
}

int frame_tostring(lua_State *L) {
  auto *ref = static_cast<FrameRef *>(luaL_checkudata(L, 1, kFrameMeta));
  if (ref->ptr) lua_pushfstring(L, "Frame(%dx%d)", ref->ptr->width, ref->ptr->height);
  else lua_pushstring(L, "Frame(expired)");
  return 1;
}

int host_print(lua_State *L) {              // print() with the script name in front
  // Build the line on the Lua stack, not in a std::string: tostring may raise
  // (a __tostring metamethod can call error), and a Lua error longjmps past
  // C++ destructors.
  int n = lua_gettop(L);
  lua_pushfstring(L, "  [%s]", lua_tostring(L, lua_upvalueindex(1)));
  for (int i = 1; i <= n; ++i) {
    lua_pushstring(L, i == 1 ? " " : "\t");
    lua_getglobal(L, "tostring");           // the real global table, not the sandbox
    lua_pushvalue(L, i);
    lua_call(L, 1, 1);
    if (!lua_isstring(L, -1)) return luaL_error(L, "'tostring' must return a string");
    lua_concat(L, 3);
  }
  std::printf("%s\n", lua_tostring(L, -1));
  return 0;
}

// pcall for scripts. A plain pcall would let a script catch the
// "instruction limit exceeded" error and carry on forever, so once the
// budget is gone this one re-raises instead of returning false.
int host_pcall(lua_State *L) {
  luaL_checkany(L, 1);
  int status = lua_pcall(L, lua_gettop(L) - 1, LUA_MULTRET, 0);
  void *ud = nullptr;
  lua_getallocf(L, &ud);
  if (static_cast<Script *>(ud)->steps_exhausted()) return luaL_error(L, "instruction limit exceeded");
  lua_pushboolean(L, status == LUA_OK);
  lua_insert(L, 1);
  return lua_gettop(L);
}

// copy table `lib` from the real globals into env, leaving out `skip`
void copy_lib(lua_State *L, int env, const char *lib, const char *skip = nullptr) {
  lua_newtable(L);
  lua_getglobal(L, lib);
  lua_pushnil(L);
  while (lua_next(L, -2)) {
    if (skip && lua_type(L, -2) == LUA_TSTRING && std::strcmp(lua_tostring(L, -2), skip) == 0) {
      lua_pop(L, 1);
      continue;
    }
    lua_pushvalue(L, -2);
    lua_insert(L, -2);
    lua_settable(L, -5);
  }
  lua_pop(L, 1);
  lua_setfield(L, env, lib);
}
// Everything the host does to a script's state outside the script's own calls
// (opening libraries, building the environment, wrapping a frame) allocates,
// and with a memory limit any allocation can fail. An unprotected failure
// makes Lua call its panic handler and abort the whole program, so these
// steps run inside a protected call too.
using Step = void (*)(lua_State *, void *);
struct Protected { Step fn; void *arg; };

int trampoline(lua_State *L) {
  auto *p = static_cast<Protected *>(lua_touserdata(L, 1));
  lua_settop(L, 0);
  p->fn(L, p->arg);
  return 0;
}

int protect(lua_State *L, Step fn, void *arg) {
  Protected p{fn, arg};
#if LUA_VERSION_NUM < 502
  return lua_cpcall(L, trampoline, &p);    // 5.1/LuaJIT: pushing a C function allocates
#else
  lua_pushcfunction(L, trampoline);        // a light C function: no allocation
  lua_pushlightuserdata(L, &p);
  return lua_pcall(L, 1, 0, 0);
#endif
}

void setup_state(lua_State *L, void *) {
  luaL_openlibs(L);
  // string.dump would turn functions into bytecode; strings share one
  // metatable whose __index is the global string table, so remove it there
  lua_getglobal(L, "string");
  lua_pushnil(L);
  lua_setfield(L, -2, "dump");
  lua_pop(L, 1);

  luaL_newmetatable(L, kFrameMeta);
  lua_pushcfunction(L, frame_index);
  lua_setfield(L, -2, "__index");
  lua_pushcfunction(L, frame_tostring);
  lua_setfield(L, -2, "__tostring");
  lua_newtable(L);
  lua_pushcfunction(L, frame_get);
  lua_setfield(L, -2, "get");
  lua_pushcfunction(L, frame_set);
  lua_setfield(L, -2, "set");
  lua_setfield(L, -2, "methods");
  lua_pushboolean(L, 0);
  lua_setfield(L, -2, "__metatable");      // getmetatable(frame) returns false
  lua_pop(L, 1);
}

struct EnvArgs { const std::string *name; const std::map<std::string, std::string> *params; };

// the environment: a whitelist of safe functions and fresh library copies,
// stored in the registry as "mediapipe.env"
void build_env(lua_State *L, void *ud) {
  auto *a = static_cast<EnvArgs *>(ud);
  lua_newtable(L);
  const int env = lua_gettop(L);
  for (const char *fn : {"assert", "error", "ipairs", "next", "pairs", "select",
                         "tonumber", "tostring", "type", "unpack", "setmetatable",
                         "rawequal", "rawget", "rawset", "rawlen"}) {
    lua_getglobal(L, fn);                   // unpack/rawlen exist in only some versions
    lua_setfield(L, env, fn);
  }
  copy_lib(L, env, "string", "dump");
  copy_lib(L, env, "table");
  copy_lib(L, env, "math");
  lua_pushcfunction(L, host_pcall);
  lua_setfield(L, env, "pcall");
  lua_pushstring(L, a->name->c_str());
  lua_pushcclosure(L, host_print, 1);
  lua_setfield(L, env, "print");
  lua_newtable(L);
  for (const auto &[k, v] : *a->params) {
    lua_pushstring(L, v.c_str());
    if (lua_isnumber(L, -1)) lua_pushnumber(L, lua_tonumber(L, -1)), lua_remove(L, -2);
    lua_setfield(L, -2, k.c_str());
  }
  lua_setfield(L, env, "params");
  lua_setfield(L, LUA_REGISTRYINDEX, "mediapipe.env");     // to find process() later
}

// the frame handle for one process() call, stored as "mediapipe.current"
void wrap_frame(lua_State *L, void *frame) {
  auto *ref = static_cast<FrameRef *>(lua_newuserdata(L, sizeof(FrameRef)));
  ref->ptr = static_cast<Frame *>(frame);
  luaL_getmetatable(L, kFrameMeta);
  lua_setmetatable(L, -2);
  lua_setfield(L, LUA_REGISTRYINDEX, "mediapipe.current");
}
}  // namespace

Script::Script(std::string name, Limits limits) : name_(std::move(name)), limits_(limits) {
#if LUA_VERSION_NUM >= 505
  L_ = lua_newstate(alloc, this, luaL_makeseed(nullptr));   // 5.5 takes a hash seed
#else
  L_ = lua_newstate(alloc, this);
#endif
  if (!L_) { error_ = "could not create a Lua state"; return; }
  if (protect(L_, setup_state, nullptr) != LUA_OK) {
    error_ = "could not set up a Lua state within the memory limit";
    lua_close(L_);
    L_ = nullptr;
    return;
  }
#ifdef LUAJIT_VERSION
  // LuaJIT runs hooks only in its interpreter, never inside compiled traces,
  // so the instruction limit needs the JIT off for this state. (After
  // luaL_openlibs: opening the jit library switches the JIT on.)
  luaJIT_setmode(L_, 0, LUAJIT_MODE_ENGINE | LUAJIT_MODE_OFF);
#endif
}

Script::~Script() {
  if (L_) lua_close(L_);
}

void *Script::alloc(void *ud, void *ptr, std::size_t osize, std::size_t nsize) {
  auto *self = static_cast<Script *>(ud);
  if (!ptr) osize = 0;                      // for new blocks osize is a type tag
  if (nsize == 0) {
    std::free(ptr);
    self->used_ -= osize;
    return nullptr;
  }
  if (nsize > osize && self->used_ + (nsize - osize) > self->limits_.memory_bytes) {
    return nullptr;                         // Lua turns NULL into a memory error
  }
  void *p = std::realloc(ptr, nsize);
  if (p) self->used_ = self->used_ - osize + nsize;
  return p;
}

// --8<-- [start:limits]
void Script::count_hook(lua_State *L, lua_Debug *) {
  void *ud = nullptr;
  lua_getallocf(L, &ud);                    // our Script* rides along as the allocator's ud
  auto *self = static_cast<Script *>(ud);
  self->budget_ -= kHookEvery;
  if (self->budget_ < 0) {
    self->out_of_steps_ = true;
    luaL_error(L, "instruction limit exceeded");
  }
  // the same hook enforces wall-clock time, for time spent in C functions
  // the script calls, which the instruction count does not see
  if (std::chrono::steady_clock::now() > self->deadline_) {
    self->out_of_time_ = true;
    luaL_error(L, "time limit exceeded");
  }
}

bool Script::call(int nargs) {
  budget_ = limits_.instructions;
  deadline_ = std::chrono::steady_clock::now() +
              std::chrono::duration_cast<std::chrono::steady_clock::duration>(
                  std::chrono::duration<double>(limits_.seconds));
  out_of_steps_ = out_of_time_ = false;
  lua_sethook(L_, count_hook, LUA_MASKCOUNT, kHookEvery);
  int status = lua_pcall(L_, nargs, 0, 0);
  lua_sethook(L_, nullptr, 0, 0);
  // The hook only runs between Lua instructions. One long C call (a
  // backtracking string.find, say) can overrun the deadline and then return
  // with too few instructions left for the hook to fire again, so check once
  // more here. This detects the overrun; it cannot interrupt it.
  if (status == LUA_OK && std::chrono::steady_clock::now() > deadline_) {
    char buf[96];
    std::snprintf(buf, sizeof buf, "time limit exceeded (%.2f s), detected after the call returned",
                  limits_.seconds);
    error_ = buf;
    return false;
  }
  if (status == LUA_OK) return true;
  if (out_of_steps_) {
    error_ = "instruction limit exceeded (" + std::to_string(limits_.instructions) + ")";
  } else if (out_of_time_) {
    char buf[64];
    std::snprintf(buf, sizeof buf, "time limit exceeded (%.2f s)", limits_.seconds);
    error_ = buf;
  } else if (status == LUA_ERRMEM) {
    error_ = "memory limit exceeded (" + std::to_string(limits_.memory_bytes / 1024) + " KiB)";
  } else {
    const char *msg = lua_tostring(L_, -1);
    error_ = msg ? msg : "(error object is not a string)";
  }
  lua_pop(L_, 1);
  lua_gc(L_, LUA_GCCOLLECT, 0);             // give back what the failed call held
  return false;
}
// --8<-- [end:limits]

bool Script::load(const std::string &path, const std::map<std::string, std::string> &params) {
  if (!L_) return false;
  std::ifstream in(path, std::ios::binary);
  if (!in) { error_ = "cannot open " + path; return false; }
  std::stringstream ss;
  ss << in.rdbuf();
  const std::string src = ss.str();
  // mode "t": text only. Precompiled bytecode can crash the VM, so refuse it.
  int status = luaL_loadbufferx(L_, src.data(), src.size(), ("@" + path).c_str(), "t");
  if (status != LUA_OK) {
    error_ = status == LUA_ERRMEM
                 ? "memory limit exceeded (" + std::to_string(limits_.memory_bytes / 1024) + " KiB)"
                 : lua_tostring(L_, -1);
    lua_pop(L_, 1);
    return false;
  }
  EnvArgs args{&name_, &params};
  if (protect(L_, build_env, &args) != LUA_OK) {
    lua_pop(L_, 2);                         // the error and the chunk
    error_ = "memory limit exceeded (" + std::to_string(limits_.memory_bytes / 1024) + " KiB)";
    return false;
  }
  lua_getfield(L_, LUA_REGISTRYINDEX, "mediapipe.env");
#if LUA_VERSION_NUM >= 502
  lua_setupvalue(L_, -2, 1);                // a main chunk's first upvalue is _ENV
#else
  lua_setfenv(L_, -2);                      // 5.1/LuaJIT: function environments
#endif
  return call(0);
}

bool Script::process(Frame &frame) {
  lua_getfield(L_, LUA_REGISTRYINDEX, "mediapipe.env");
  lua_getfield(L_, -1, "process");
  lua_remove(L_, -2);
  if (lua_type(L_, -1) != LUA_TFUNCTION) {
    lua_pop(L_, 1);
    error_ = "script does not define process(frame)";
    return false;
  }
  Frame backup = frame;                     // a failed filter must not leave half its work
  if (protect(L_, wrap_frame, &frame) != LUA_OK) {
    lua_pop(L_, 2);                         // the error and process
    error_ = "memory limit exceeded (" + std::to_string(limits_.memory_bytes / 1024) + " KiB)";
    return false;
  }
  lua_getfield(L_, LUA_REGISTRYINDEX, "mediapipe.current");  // kept there to expire it later
  bool ok = call(1);
  lua_getfield(L_, LUA_REGISTRYINDEX, "mediapipe.current");
  static_cast<FrameRef *>(lua_touserdata(L_, -1))->ptr = nullptr;
  lua_pop(L_, 1);
  if (!ok) frame = backup;
  return ok;
}
