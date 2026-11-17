# 20. The C API I: Embedding Lua in C and C++

--8<-- "includes/badges/20-capi-embed.md"

!!! abstract "What you will be able to do after this lesson"
    - Create, use and close a `lua_State` from C and C++, and link against Lua 5.5, 5.4 or LuaJIT.
    - Move values between C and Lua through the virtual stack, keeping it balanced.
    - Call Lua functions from C and expose C functions to Lua.
    - Handle errors with `lua_pcall`, message handlers, error objects and memory limits.
    - Wrap all of it in safe C++: RAII, exceptions, and no `longjmp` over destructors.

## Intuition: one stack, many states

Lua is a C library. A `lua_State` is a complete, independent interpreter: globals,
registry, heap and collector. You can create as many as you like (one per
thread, per plugin, per request); they share nothing. All communication between
C and that state goes through a **virtual stack** of Lua values: C pushes
arguments, calls, and pops results. C never holds a raw pointer to a Lua table;
it holds a stack *index*.

!!! note "For C++/Rust developers"
    The API is deliberately low-level and unsafe: indices are plain `int`s, nothing
    checks the stack is balanced, and Lua reports errors with `longjmp` (when built
    as C), which skips C++ destructors. The usual answer is a thin wrapper that owns
    the state, restores the stack on scope exit and converts errors at the boundary,
    as in the C++ example below. Rust's `mlua` (Lesson 22) does the same job with
    the type system.

## Building against each interpreter

Every C and C++ example in this lesson is compiled three times by the test
runner, against each interpreter's own headers and static library:

```bash
# Lua 5.5 (5.4 is the same with lua-5.4.9)
gcc -std=c11 -O2 -Wall -Wextra -I/opt/lua-5.5.1/include embed_hello.c \
    /opt/lua-5.5.1/lib/liblua.a -lm -ldl -Wl,-E -o embed_hello
# LuaJIT 2.1: headers in include/luajit-2.1, library libluajit-5.1
gcc -std=c11 -O2 -Wall -Wextra -I/opt/luajit-2.1/include/luajit-2.1 embed_hello.c \
    /opt/luajit-2.1/lib/libluajit-5.1.a -lm -ldl -Wl,-E -o embed_hello
# C++: same flags with g++ -std=c++17; include <lua.hpp>, which wraps the C headers
```

`-Wl,-E` exports the Lua API from the executable so that C modules loaded later
with `require` (Lesson 21) can find it. The same source compiles everywhere
thanks to a small compatibility header, because LuaJIT implements the Lua 5.1
API plus a few 5.2 functions:

```c title="examples/20-capi-embed/lua_compat.h"
--8<-- "examples/20-capi-embed/lua_compat.h"
```

## Hello, embedded Lua

```c title="examples/20-capi-embed/embed_hello.c"
--8<-- "examples/20-capi-embed/embed_hello.c"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/20-capi-embed/embed_hello.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/20-capi-embed/embed_hello.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/20-capi-embed/embed_hello.jit.expected"
    ```

## The virtual stack

Positive indices count from the bottom (1 is the first value), negative from
the top (-1 is the last pushed). `lua_gettop` is the number of values.

```c title="examples/20-capi-embed/stack.c"
--8<-- "examples/20-capi-embed/stack.c"
```

```text
--8<-- "examples/20-capi-embed/stack.expected"
```

!!! warning "Conversions happen in place"
    `lua_tostring` on a number **changes the stack slot into a string**. Never call it
    on a key during `lua_next` traversal, and do not rely on argument evaluation order
    in a single `printf` call that also inspects the slot.

## Calling Lua from C

A configuration file:

```lua title="examples/20-capi-embed/config.lua"
--8<-- "examples/20-capi-embed/config.lua"
```

read and called from C:

```c title="examples/20-capi-embed/call_lua.c"
--8<-- "examples/20-capi-embed/call_lua.c"
```

```text
--8<-- "examples/20-capi-embed/call_lua.expected"
```

The pattern for every call: push the function, push the arguments, `lua_pcall(L,
nargs, nresults, msgh)`, read the results at negative indices, pop them. Note how
the C code checks the type returned by `lua_getfield` (5.3+; the compat header
emulates it on LuaJIT) and supplies a default for the missing `fps` field.

## Calling C from Lua

A C function has the signature `int f(lua_State *L)`: arguments are at stack
indices 1..n, it pushes its results and returns how many there are.

```c title="examples/20-capi-embed/call_c.c"
--8<-- "examples/20-capi-embed/call_c.c"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/20-capi-embed/call_c.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/20-capi-embed/call_c.jit.expected"
    ```

- `luaL_check*` and `luaL_opt*` validate arguments and raise standard error messages.
- `luaL_newlib` builds a module table from a `luaL_Reg` array (LuaJIT 2.1 has it too).
- `lua_pushnumber` creates a float on 5.3+, so `clamp(1.5)` prints `1.0`; use
  `lua_pushinteger` for integers.
- When a C function is called through `pcall`, LuaJIT cannot name it and reports
  `bad argument #1 to '?'`. PUC Lua searches `package.loaded` (which includes `_G`)
  for the function and finds the global `clamp`, the same C function.

## Errors

```c title="examples/20-capi-embed/errors.c"
--8<-- "examples/20-capi-embed/errors.c"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/20-capi-embed/errors.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/20-capi-embed/errors.jit.expected"
    ```

- `luaL_loadbuffer` reports `LUA_ERRSYNTAX` without running anything; `lua_pcall`
  returns `LUA_ERRRUN`, `LUA_ERRMEM` or `LUA_ERRERR` (error in the message handler).
- The **message handler** runs before the stack unwinds, which is the only time a
  traceback is available. It should pass non-string error objects through untouched.
- A custom allocator (`lua_newstate`) is how you cap a state's memory. In Lua 5.5
  `lua_newstate` takes a third argument, a seed for string hashing (`luaL_makeseed`).
- **Emergency GC**: when an allocation fails, Lua 5.4/5.5 run a full collection and
  retry, so the state was usable again immediately. LuaJIT raises the memory
  error straight away, and the state only recovered after an explicit `lua_gc`.

!!! danger "Unprotected errors"
    An error outside any `lua_pcall` calls the panic function and then `abort()`s
    the process. In a host program, run *all* Lua code (including `lua_getfield` on
    tables with metamethods, which can raise errors) inside a protected call.

## A C++ wrapper with RAII

```cpp title="examples/20-capi-embed/raii.cpp"
--8<-- "examples/20-capi-embed/raii.cpp"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/20-capi-embed/raii.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/20-capi-embed/raii.jit.expected"
    ```

The rules the wrapper enforces:

1. **Ownership**: `std::unique_ptr<lua_State, decltype(&lua_close)>` closes the state
   exactly once, also on exceptions.
2. **Stack balance**: `StackGuard` restores the top on every exit path.
3. **Errors → exceptions** at the boundary: every Lua call is a `lua_pcall`, and a
   non-zero status becomes a `LuaError`.
4. **Exceptions → Lua errors** in the trampoline: catch everything, copy the message
   onto the Lua stack, let all C++ objects in the frame die, *then* call `lua_error`.
   Argument conversion throws C++ exceptions instead of using `luaL_check*`, whose
   `longjmp` would skip the destructors of live C++ objects.
5. **C++ objects inside Lua**: the `std::function` lives in a full userdata, built
   with placement `new` and destroyed by a `__gc` metamethod (Lesson 21).

!!! info "Lua built as C++"
    If you compile the Lua sources as C++, `LUAI_THROW` uses C++ exceptions instead of
    `longjmp`, and destructors do run. That only works when the whole program,
    including every C module, is built against the same C++-compiled Lua. On x64
    Linux, LuaJIT has its own unwinder that interoperates with C++ exceptions;
    the rules above are still the portable approach.

## Hands-on exercises

??? example "Exercise 1: a sandbox"
    Run untrusted code with an environment that only contains `print`, `math`, `string`, `tostring` and `type`, on Lua 5.2+ (`_ENV` upvalue) and LuaJIT (`lua_setfenv`).

    ??? success "Solution"
        ```c
        --8<-- "examples/20-capi-embed/ex1_sandbox.c"
        ```
        === "Lua 5.5 / 5.4"
            ```text
            --8<-- "examples/20-capi-embed/ex1_sandbox.expected"
            ```
        === "LuaJIT 2.1"
            ```text
            --8<-- "examples/20-capi-embed/ex1_sandbox.jit.expected"
            ```

??? example "Exercise 2: stop runaway scripts"
    Abort a script after a fixed number of VM instructions with a count hook.

    ??? success "Solution"
        ```c
        --8<-- "examples/20-capi-embed/ex2_timeout.c"
        ```
        ```text
        --8<-- "examples/20-capi-embed/ex2_timeout.expected"
        ```
        On LuaJIT the JIT must be switched off for that state: compiled traces do not call count hooks.

??? example "Exercise 3: std::vector round trip"
    Pass a `std::vector<double>` to a Lua function as a table and convert the returned table back.

    ??? success "Solution"
        ```cpp
        --8<-- "examples/20-capi-embed/ex3_vector.cpp"
        ```
        ```text
        --8<-- "examples/20-capi-embed/ex3_vector.expected"
        ```

## Quiz

??? question "Q1. After `lua_pushinteger(L, 1); lua_pushstring(L, \"a\");`, what are indices 1, -1 and -2?"
    Index 1 is `1`, index -1 is `"a"`, index -2 is `1` (when the stack was empty before).

??? question "Q2. What must a C function registered with Lua return?"
    The number of results it pushed onto the stack.

??? question "Q3. Why is calling `luaL_checkinteger` inside a C++ function with a live `std::string` dangerous?"
    On error it `longjmp`s out of the function (Lua built as C), skipping the
    `std::string` destructor: a leak or worse. Validate first, or convert C++
    exceptions to `lua_error` only after the C++ objects are destroyed.

??? question "Q4. Where do you get a traceback for an error raised inside `lua_pcall`?"
    In a message handler passed as `msgh`; it runs before the stack unwinds and can call `luaL_traceback`.

??? question "Q5. What changed in `lua_newstate` in Lua 5.5?"
    It takes a third argument, a seed for string hashing (for example `luaL_makeseed(NULL)`).
