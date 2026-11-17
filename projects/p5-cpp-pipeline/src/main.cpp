// mediapipe: run a synthetic test frame through a chain of Lua filter scripts.
//
//   mediapipe [--frames N] [--memory KiB] [--instructions N] [--seconds S]
//             [--size WxH] script.lua[:key=value,...] ...
//   mediapipe --version
//
// Each script runs in its own sandboxed Lua state, loaded once and called
// for every frame. A script that fails (error, limit, missing process) is
// reported and unloaded; the frame keeps the result of the filters before it
// (a failed filter's partial changes are rolled back), and the exit status is 1.
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "frame.hpp"
#include "sandbox.hpp"
#if defined(__has_include)
#if __has_include(<luajit.h>)
#include <luajit.h>
#endif
#endif

namespace {
struct Step {
  std::string path;
  std::map<std::string, std::string> params;
};

Step parse_step(const std::string &arg) {   // "scripts/b.lua:amount=40,gamma=2"
  Step s;
  auto colon = arg.find(':');
  s.path = arg.substr(0, colon);
  if (colon == std::string::npos) return s;
  std::string rest = arg.substr(colon + 1);
  size_t start = 0;
  while (start <= rest.size()) {
    size_t comma = rest.find(',', start);
    std::string kv = rest.substr(start, comma == std::string::npos ? std::string::npos : comma - start);
    auto eq = kv.find('=');
    if (eq != std::string::npos) s.params[kv.substr(0, eq)] = kv.substr(eq + 1);
    if (comma == std::string::npos) break;
    start = comma + 1;
  }
  return s;
}

std::string basename_of(const std::string &path) {
  auto slash = path.find_last_of('/');
  return slash == std::string::npos ? path : path.substr(slash + 1);
}
}  // namespace

int main(int argc, char **argv) {
  Limits limits;
  int width = 48, height = 24, frames = 1;
  std::vector<Step> steps;
  for (int i = 1; i < argc; ++i) {
    std::string a = argv[i];
    if (a == "--frames" && i + 1 < argc) frames = std::atoi(argv[++i]);
    else if (a == "--memory" && i + 1 < argc) limits.memory_bytes = std::strtoul(argv[++i], nullptr, 10) * 1024;
    else if (a == "--seconds" && i + 1 < argc) limits.seconds = std::atof(argv[++i]);
    else if (a == "--version") {
#ifdef LUAJIT_VERSION
      std::printf("mediapipe 1.0, %s (Lua 5.1 API)\n", LUAJIT_VERSION);
#else
      std::printf("mediapipe 1.0, %s\n", LUA_RELEASE);
#endif
      return 0;
    } else if (a == "--instructions" && i + 1 < argc) limits.instructions = std::strtol(argv[++i], nullptr, 10);
    else if (a == "--size" && i + 1 < argc) std::sscanf(argv[++i], "%dx%d", &width, &height);
    else steps.push_back(parse_step(a));
  }
  if (steps.empty()) {
    std::fprintf(stderr, "usage: mediapipe [--frames N] [--memory KiB] [--instructions N] [--seconds S] [--size WxH] "
                         "script.lua[:k=v,...]...\n");
    return 2;
  }

  int failures = 0;
  std::vector<std::unique_ptr<Script>> scripts;   // a Script owns a lua_State: not copyable
  for (const auto &step : steps) {
    auto script = std::make_unique<Script>(basename_of(step.path), limits);
    std::printf("load %s\n", step.path.c_str());   // print() lines from the main chunk follow
    if (script->load(step.path, step.params)) scripts.push_back(std::move(script));
    else { std::printf("  -> FAILED: %s\n", script->error().c_str()); ++failures; }
  }

  Frame frame(width, height);
  for (int t = 0; t < frames; ++t) {
    frame = Frame::test_pattern(width, height, t);
    std::printf("frame %d\n  %-15s %s\n", t, "input", frame.stats().c_str());
    if (t == 0) std::printf("%s", frame.ascii(48).c_str());
    for (auto &script : scripts) {
      if (!script) continue;                // unloaded after an earlier failure
      if (script->process(frame)) {
        std::printf("  %-15s %s\n", script->name().c_str(), frame.stats().c_str());
      } else {
        std::printf("  %-15s FAILED: %s (unloaded)\n", script->name().c_str(), script->error().c_str());
        script.reset();
        ++failures;
      }
    }
  }
  std::printf("output\n%s", frame.ascii(48).c_str());
  return failures ? 1 : 0;
}
