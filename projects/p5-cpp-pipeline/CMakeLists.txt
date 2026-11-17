# mediapipe: a C++ media pipeline whose filters are sandboxed Lua scripts.
#
#   cmake -S . -B build -DLUA_INCLUDE_DIR=/opt/lua-5.5.1/include \
#         -DLUA_LIBRARY=/opt/lua-5.5.1/lib/liblua.a
#   cmake --build build
#
# Without those two variables CMake's FindLua looks for a system Lua
# (e.g. Debian's liblua5.4-dev). For LuaJIT pass its include/luajit-2.1
# directory and libluajit-5.1.a.
cmake_minimum_required(VERSION 3.16)
project(mediapipe LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

if(NOT LUA_INCLUDE_DIR OR NOT LUA_LIBRARY)
  find_package(Lua REQUIRED)            # sets LUA_INCLUDE_DIR, LUA_LIBRARIES
  set(LUA_LIBRARY ${LUA_LIBRARIES})
endif()

add_executable(mediapipe src/main.cpp src/sandbox.cpp src/frame.cpp)
target_include_directories(mediapipe PRIVATE ${LUA_INCLUDE_DIR})
target_link_libraries(mediapipe PRIVATE ${LUA_LIBRARY} ${CMAKE_DL_LIBS} m)
target_compile_options(mediapipe PRIVATE -Wall -Wextra -Werror)
# a static liblua.a needs its symbols exported only if scripts load C modules;
# ours never do (require is not available in the sandbox)

message(STATUS "Lua headers: ${LUA_INCLUDE_DIR}")
message(STATUS "Lua library: ${LUA_LIBRARY}")
