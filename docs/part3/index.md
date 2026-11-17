# Part 3: Systems Lua

Lua as a component of native software: how LuaJIT makes Lua fast, how its FFI
calls C directly, and how C, C++ and Rust programs embed Lua and extend it.
Every C and C++ example is compiled against **each** interpreter's own headers
and static library (Lua 5.5.1, Lua 5.4.9, LuaJIT 2.1) and run by the test suite;
the Rust examples are built three times with `mlua`, once per Lua version.

| # | Lesson | You will learn |
|---|---|---|
| 18 | [LuaJIT: The Trace Compiler](18-luajit.md) | Traces, `-jv` and `-jdump`, what aborts traces, the 5.1 dialect, the new 2.1-branch syntax caveat |
| 19 | [The LuaJIT FFI](19-ffi.md) | `ffi.cdef`, libc and your own `.so`, structs and arrays, `ffi.gc`, callbacks, measured performance |
| 20 | [The C API I: Embedding](20-capi-embed.md) | `lua_State`, the virtual stack, calling in both directions, `lua_pcall` errors, a C++ RAII wrapper |
| 21 | [The C API II: C Modules](21-capi-modules.md) | Modules for `require`, userdata with `__gc`/`__close`, light userdata, registry references, upvalues |
| 22 | [Lua from Rust with `mlua`](22-mlua.md) | Embedding, `UserData`, error conversion, feature flags for Lua 5.5, 5.4 and LuaJIT |

!!! tip "Toolchain"
    You need `gcc`/`g++` (C11 and C++17) for Lessons 20–21 and the custom library in
    Lesson 19, and a Rust toolchain (`rustup`, Rust 1.88 or newer) for Lesson 22.
    The interpreters built by `scripts/install-interpreters.sh` already include the
    headers and static libraries.
