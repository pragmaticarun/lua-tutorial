# 21. The C API II: Writing C Modules

--8<-- "includes/badges/21-capi-modules.md"

!!! abstract "What you will be able to do after this lesson"
    - Write a C module that `require` loads from a shared library, for Lua 5.5, 5.4 and LuaJIT.
    - Define userdata types with metatables, methods and operators, checked with `luaL_checkudata`.
    - Own C resources safely with `close()`, `__close` and `__gc`.
    - Keep Lua values alive from C with registry references, and give C functions private state with upvalues.
    - Use light userdata as unique keys, and user values to link userdata to Lua tables.

## Intuition: a module is one exported C function

`require("vec")` searches `package.cpath` for `vec.so`, opens it with
`dlopen`, looks up the symbol `luaopen_vec` and calls it like any C function.
Whatever it returns (normally a table of functions) becomes the module. Lua
values created by the module live in the Lua heap; C data lives either inside a
**full userdata** (a block of memory managed by the collector) or in `malloc`ed
memory owned by such a userdata.

!!! note "For C++/Rust developers"
    A full userdata is like a `Box<T>` whose owner is the Lua GC; its metatable is
    the vtable (methods, operators, destructor). `luaL_checkudata` is a checked
    `dynamic_cast`. A light userdata is a raw `void *`, with no metatable of its own
    and no lifetime management at all.

## Building and loading

```bash
# one .so per interpreter: the Lua API is resolved from the host executable
gcc -O2 -shared -fPIC -I/opt/lua-5.5.1/include            -o build/5.5/vec.so vec.c
gcc -O2 -shared -fPIC -I/opt/luajit-2.1/include/luajit-2.1 -o build/jit/vec.so vec.c
LUA_CPATH="./build/5.5/?.so;;" lua5.5 use_vec.lua
```

The test runner does exactly this for each interpreter, and runs the Lua
scripts with `LUA_CPATH` pointing at the matching build. A module compiled
against 5.4 headers must not be loaded into 5.5 or LuaJIT: the ABI differs, and
the crash will not be friendly. Do not link the module against `liblua.a`
either, or the process ends up with two copies of the Lua core.

## A userdata type

```c title="examples/21-capi-modules/vec.c"
--8<-- "examples/21-capi-modules/vec.c"
```

```lua title="examples/21-capi-modules/use_vec.lua"
--8<-- "examples/21-capi-modules/use_vec.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/21-capi-modules/use_vec.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/21-capi-modules/use_vec.jit.expected"
    ```

Details worth copying:

- The metatable is created once, under a unique name in the registry
  (`luaL_newmetatable` returns 0 if it already exists, for example when two states
  load the module, or `package.loaded` was cleared).
- `__index` points at a separate methods table, so `a:len()` works while `a.x`
  stays inaccessible. To expose fields, make `__index` a C function (Exercise 2).
- Error messages name the expected type: the name given to `luaL_newmetatable`
  (Lua 5.3+ also store it as the metatable's `__name` field).
- Lua 5.4/5.5 name the metamethod `'add'` in errors, LuaJIT `'__add'`;
  `lua_pushfstring("%f")` prints `4.0` on 5.4/5.5 and `4` on LuaJIT.

## Owning a C resource

```c title="examples/21-capi-modules/buffer.c"
--8<-- "examples/21-capi-modules/buffer.c"
```

```lua title="examples/21-capi-modules/use_buffer.lua"
--8<-- "examples/21-capi-modules/use_buffer.lua"
```

```text
--8<-- "examples/21-capi-modules/use_buffer.expected"
```

On Lua 5.4 and 5.5 the same metatable's `__close` makes the buffer usable with `<close>`:

```lua title="examples/21-capi-modules/use_buffer_close.lua"
--8<-- "examples/21-capi-modules/use_buffer_close.lua"
```

```text
--8<-- "examples/21-capi-modules/use_buffer_close.expected"
```

The rules for resource-owning userdata:

1. **Put the object in a safe state before anything can fail**: `data = NULL`
   before `luaL_setmetatable` and `calloc`. If an allocation error is raised,
   `__gc` will still run on the half-built object.
2. **Release must be idempotent**: `close()`, `__close` and `__gc` can all run for
   the same object, in any combination.
3. **Every method checks for "closed"**; a userdata can be used after `__gc` if it
   was resurrected by another finalizer.
4. **Per-state data** goes in the registry or in upvalues, not in C `static`
   variables, so that several `lua_State`s in one process stay independent. The
   key here is a **light userdata**: the address of a `static` variable, which no
   other module can collide with.

## The registry, references and upvalues

```c title="examples/21-capi-modules/events.c"
--8<-- "examples/21-capi-modules/events.c"
```

```lua title="examples/21-capi-modules/use_events.lua"
--8<-- "examples/21-capi-modules/use_events.lua"
```

```text
--8<-- "examples/21-capi-modules/use_events.expected"
```

- **References**: `luaL_ref(L, LUA_REGISTRYINDEX)` pops a value, stores it in
  the registry and returns an integer key; `lua_rawgeti` fetches it back,
  `luaL_unref` releases it. This is how C code holds on to Lua callbacks. Forgetting
  `luaL_unref` is a leak; the reference numbers themselves are an implementation
  detail.
- **Upvalues of C closures**: `luaL_setfuncs(L, list, 1)` gives every function in
  `list` the same upvalue (here the table of refs), shared module state without
  globals. `lua_pushcclosure(L, f, 1)` creates one closure with its own private
  upvalue, like the counters.
- `lua_call` propagates errors to whoever called `emit`; use `lua_pcall` when C code
  must regain control (Exercise 3).

## Version differences in the C API

| Topic | Lua 5.5 | Lua 5.4 | LuaJIT 2.1 |
|---|---|---|---|
| `lua_newstate` | `(alloc, ud, seed)` | `(alloc, ud)` | `(alloc, ud)` |
| `luaL_openlibs` | macro for `luaL_openselectedlibs` | function | function |
| Userdata extra values | `lua_newuserdatauv`, `lua_setiuservalue` | same | one environment table (`lua_setfenv`) |
| `__close` / `lua_toclose` | yes | yes | no |
| `lua_rawlen`, `lua_absindex`, `lua_rawgetp`/`setp` | yes | yes | no (`lua_objlen`; emulate the rest) |
| `lua_getfield` returns the type | yes | yes | no (`void`) |
| `luaL_setfuncs`, `luaL_newlib`, `luaL_testudata`, `luaL_traceback` | yes | yes | yes (5.2 additions in 2.1) |
| Globals table | `LUA_RIDX_GLOBALS` in the registry | same | `LUA_GLOBALSINDEX` pseudo-index |
| C function names in error messages | from `package.loaded` | same | often `'?'` |

## Hands-on exercises

??? example "Exercise 1: a string module"
    Write `trim`, `startswith` and `count` in C. Use explicit lengths, since Lua strings may contain zero bytes.

    ??? success "Solution"
        ```c
        --8<-- "examples/21-capi-modules/ex1_strutil.c"
        ```
        ```lua
        --8<-- "examples/21-capi-modules/ex1_test.lua"
        ```
        === "Lua 5.5 / 5.4"
            ```text
            --8<-- "examples/21-capi-modules/ex1_test.expected"
            ```
        === "LuaJIT 2.1"
            ```text
            --8<-- "examples/21-capi-modules/ex1_test.jit.expected"
            ```

??? example "Exercise 2: user values"
    Make a userdata that carries a Lua table of metadata and exposes it through `__index`, keeping the table alive exactly as long as the userdata.

    ??? success "Solution"
        ```c
        --8<-- "examples/21-capi-modules/ex2_node.c"
        ```
        ```lua
        --8<-- "examples/21-capi-modules/ex2_test.lua"
        ```
        ```text
        --8<-- "examples/21-capi-modules/ex2_test.expected"
        ```

??? example "Exercise 3: calling Lua from a C module"
    Write `map(t, f)` with `lua_call`, and `try_map` that catches errors with `lua_pcall` and returns `false, err`.

    ??? success "Solution"
        ```c
        --8<-- "examples/21-capi-modules/ex3_map.c"
        ```
        ```lua
        --8<-- "examples/21-capi-modules/ex3_test.lua"
        ```
        === "Lua 5.5 / 5.4"
            ```text
            --8<-- "examples/21-capi-modules/ex3_test.expected"
            ```
        === "LuaJIT 2.1"
            ```text
            --8<-- "examples/21-capi-modules/ex3_test.jit.expected"
            ```

## Quiz

??? question "Q1. What symbol does `require(\"a.b\")` look for in `a/b.so`?"
    `luaopen_a_b` (dots become underscores).

??? question "Q2. Why should `__gc` and `close()` share one idempotent release function?"
    Both may run for the same object (explicit close, then collection), and a
    double `free` is undefined behaviour.

??? question "Q3. How does C code keep a Lua function alive between calls?"
    Store it in the registry with `luaL_ref` and keep the integer reference;
    release it with `luaL_unref`.

??? question "Q4. Why use the address of a `static` variable as a registry key?"
    It is a light userdata that is unique in the process, so it cannot clash with
    string keys or other modules' keys.

??? question "Q5. Can a C module compiled against Lua 5.4 headers be loaded by Lua 5.5?"
    No. The ABI and API differ between versions (for example `lua_newstate` and
    internal structures); build one module per interpreter version.
