// build: exe
// Exercise 3 solution: std::vector -> Lua table -> Lua function -> std::vector
#include <lua.hpp>
#include <iostream>
#include <stdexcept>
#include <vector>

static void push_vector(lua_State *L, const std::vector<double> &v) {
  lua_createtable(L, static_cast<int>(v.size()), 0);     // preallocate the array part
  for (size_t i = 0; i < v.size(); ++i) {
    lua_pushnumber(L, v[i]);
    lua_rawseti(L, -2, static_cast<int>(i + 1));          // Lua arrays start at 1
  }
}

static std::vector<double> to_vector(lua_State *L, int idx) {
  if (!lua_istable(L, idx)) throw std::runtime_error("table expected");
  std::vector<double> out;
  for (int i = 1;; ++i) {
    lua_rawgeti(L, idx, i);
    if (lua_isnil(L, -1)) { lua_pop(L, 1); break; }
    out.push_back(lua_tonumber(L, -1));
    lua_pop(L, 1);
  }
  return out;
}

int main() {
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  luaL_dostring(L,
    "function normalize(t)\n"
    "  local max = 0\n"
    "  for _, v in ipairs(t) do max = math.max(max, math.abs(v)) end\n"
    "  local out = {}\n"
    "  for i, v in ipairs(t) do out[i] = v / max end\n"
    "  return out\n"
    "end");
  std::vector<double> samples{0.5, -2.0, 1.0, 4.0};
  lua_getglobal(L, "normalize");
  push_vector(L, samples);
  if (lua_pcall(L, 1, 1, 0) != 0) { std::cerr << lua_tostring(L, -1) << "\n"; return 1; }
  std::vector<double> result = to_vector(L, -1);
  lua_pop(L, 1);
  for (double x : result) std::cout << x << " ";
  std::cout << "\n" << "stack top: " << lua_gettop(L) << "\n";
  lua_close(L);
  return 0;
}
