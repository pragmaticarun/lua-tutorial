// build: exe
// raii.cpp: a small C++17 wrapper - RAII for the state and the stack,
// exceptions for errors, and C++ callables exposed to Lua
#include <lua.hpp>      // lua.h + lualib.h + lauxlib.h inside extern "C"
#include <cctype>
#include <functional>
#include <iostream>
#include <memory>
#include <new>
#include <stdexcept>
#include <string>
#include <tuple>
#include <utility>

struct LuaError : std::runtime_error { using std::runtime_error::runtime_error; };

// Restores the stack top on scope exit, even when an exception is thrown.
class StackGuard {
 public:
  explicit StackGuard(lua_State *L) : L_(L), top_(lua_gettop(L)) {}
  ~StackGuard() { lua_settop(L_, top_); }
  StackGuard(const StackGuard &) = delete;
  StackGuard &operator=(const StackGuard &) = delete;
 private:
  lua_State *L_;
  int top_;
};

// push/get for a few C++ types. get() throws a C++ exception on a type
// mismatch instead of calling luaL_check*, which would longjmp over C++ frames.
inline void push(lua_State *L, double v) { lua_pushnumber(L, v); }
inline void push(lua_State *L, int v) { lua_pushinteger(L, v); }
inline void push(lua_State *L, bool v) { lua_pushboolean(L, v); }
inline void push(lua_State *L, const std::string &v) { lua_pushlstring(L, v.data(), v.size()); }
inline void push(lua_State *L, const char *v) { lua_pushstring(L, v); }

template <class T> T get(lua_State *L, int i);
template <> double get<double>(lua_State *L, int i) {
  if (lua_type(L, i) != LUA_TNUMBER) throw LuaError("number expected");
  return lua_tonumber(L, i);
}
template <> int get<int>(lua_State *L, int i) { return static_cast<int>(get<double>(L, i)); }
template <> std::string get<std::string>(lua_State *L, int i) {
  if (lua_type(L, i) != LUA_TSTRING) throw LuaError("string expected");
  size_t n;
  const char *s = lua_tolstring(L, i, &n);
  return std::string(s, n);
}

class Lua {
 public:
  Lua() : L_(luaL_newstate(), &lua_close) {
    if (!L_) throw std::bad_alloc();
    luaL_openlibs(L_.get());
  }
  lua_State *get_state() const { return L_.get(); }

  void run(const std::string &code, const char *chunkname = "=cpp") {
    StackGuard guard(L_.get());
    if (luaL_loadbuffer(L_.get(), code.data(), code.size(), chunkname) != 0 ||
        lua_pcall(L_.get(), 0, 0, 0) != 0)
      throw LuaError(lua_tostring(L_.get(), -1));
  }

  // call<R>("fn", args...) calls a global Lua function and converts the result
  template <class R, class... Args> R call(const char *fn, const Args &...args) {
    lua_State *L = L_.get();
    StackGuard guard(L);
    lua_getglobal(L, fn);
    (push(L, args), ...);                                   // C++17 fold expression
    if (lua_pcall(L, sizeof...(Args), 1, 0) != 0) throw LuaError(lua_tostring(L, -1));
    return get<R>(L, -1);
  }

  // def("name", f) exposes any std::function<R(Args...)> as a global Lua function.
  template <class R, class... Args> void def(const char *name, std::function<R(Args...)> f) {
    using Fn = std::function<R(Args...)>;
    lua_State *L = L_.get();
    void *mem = lua_newuserdata(L, sizeof(Fn));              // Lua owns the memory...
    new (mem) Fn(std::move(f));                              // ...C++ constructs into it
    lua_newtable(L);                                         // metatable with __gc
    lua_pushcfunction(L, [](lua_State *S) -> int {
      static_cast<Fn *>(lua_touserdata(S, 1))->~Fn();        // run the C++ destructor
      return 0;
    });
    lua_setfield(L, -2, "__gc");
    lua_setmetatable(L, -2);
    lua_pushcclosure(L, &trampoline<R, Args...>, 1);         // userdata = upvalue 1
    lua_setglobal(L, name);
  }

 private:
  template <class R, class... Args, std::size_t... I>
  static R invoke(lua_State *L, std::function<R(Args...)> &f, std::index_sequence<I...>) {
    return f(get<std::decay_t<Args>>(L, static_cast<int>(I) + 1)...);
  }
  template <class R, class... Args> static int trampoline(lua_State *L) {
    auto *f = static_cast<std::function<R(Args...)> *>(lua_touserdata(L, lua_upvalueindex(1)));
    {
      try {
        push(L, invoke(L, *f, std::index_sequence_for<Args...>{}));
        return 1;
      } catch (const std::exception &e) {
        lua_pushstring(L, e.what());                          // copy the message to Lua
      }
    }                                  // every C++ object in this frame is gone now...
    return lua_error(L);               // ...so the longjmp cannot skip a destructor
  }

  std::unique_ptr<lua_State, decltype(&lua_close)> L_;
};

int main() {
  try {
    Lua lua;
    lua.run("function area(w, h) return w * h end\n"
            "function greet(name) return 'hello, ' .. name end");
    std::cout << "area: " << lua.call<int>("area", 1920, 1080) << "\n";
    std::cout << lua.call<std::string>("greet", std::string("C++")) << "\n";

    int calls = 0;                                            // captured by reference
    lua.def("scale", std::function<double(double, double)>(
                         [&calls](double v, double k) { ++calls; return v * k; }));
    lua.def("upper", std::function<std::string(std::string)>([](std::string s) {
      for (auto &c : s) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
      return s;
    }));
    lua.run("print(scale(21, 2), upper('mixed Case'))\n"
            "print(pcall(scale, 'oops', 2))");
    std::cout << "scale was called " << calls << " times\n";

    std::cout << "stack top: " << lua_gettop(lua.get_state()) << "\n";
    lua.run("this is not lua");                               // throws LuaError
  } catch (const LuaError &e) {
    std::cout << "LuaError: " << e.what() << "\n";
  }
  return 0;
}
