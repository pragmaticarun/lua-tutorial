// One filter script in its own sandboxed Lua state, with resource limits.
#pragma once
#include <chrono>
#include <cstddef>
#include <map>
#include <string>

#include <lua.hpp>

#include "frame.hpp"

struct Limits {
  std::size_t memory_bytes = 1024 * 1024;   // per script state
  long instructions = 2'000'000;            // per call (load, or one process())
  double seconds = 1.0;                     // wall-clock time per call
};

class Script {
 public:
  Script(std::string name, Limits limits);
  ~Script();
  Script(const Script &) = delete;
  Script &operator=(const Script &) = delete;

  // Load the file into a fresh environment; params become the `params` table.
  bool load(const std::string &path, const std::map<std::string, std::string> &params);
  // Call the script's process(frame). On failure the frame is left unchanged.
  bool process(Frame &frame);

  const std::string &error() const { return error_; }
  const std::string &name() const { return name_; }
  bool steps_exhausted() const { return out_of_steps_ || out_of_time_; }

 private:
  static void *alloc(void *ud, void *ptr, std::size_t osize, std::size_t nsize);
  static void count_hook(lua_State *L, lua_Debug *ar);
  bool call(int nargs);                     // protected call with limits armed

  std::string name_, error_;
  Limits limits_;
  std::size_t used_ = 0;
  long budget_ = 0;
  bool out_of_steps_ = false, out_of_time_ = false;
  std::chrono::steady_clock::time_point deadline_;
  lua_State *L_ = nullptr;
};
