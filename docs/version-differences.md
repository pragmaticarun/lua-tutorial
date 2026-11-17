# Version Differences Cheat Sheet

--8<-- "includes/badges/99-version-diffs.md"

Every row below was checked by a test in this repository, either in the lesson
linked in the last column or in `examples/99-version-diffs/`. "LuaJIT" means the
pinned LuaJIT 2.1.1794386141 build from [Setup](setup.md).

## At a glance

| Topic | Lua 5.5.1 | Lua 5.4.9 | LuaJIT 2.1 | Where |
|---|---|---|---|---|
| `_VERSION` | `Lua 5.5` | `Lua 5.4` | `Lua 5.1` | [L1](part1/01-why-lua.md) |
| Integer subtype, `math.type` | yes | yes | no (doubles; FFI `1LL` int64) | [L2](part1/02-syntax-types.md) |
| Floor division `//` | yes | yes | **no** | [L2](part1/02-syntax-types.md) |
| Bitwise operators `& \| ~ << >>` | yes | yes | only builds from July 2026 on; else `bit.*` | [L1](part1/01-why-lua.md) |
| Float to string | 14 digits, **17 if needed to round-trip** | always `%.14g` | always `%.14g` | [L2](part1/02-syntax-types.md) |
| `io.write(1.0)` | `1.0` | `1` | `1` | [L3](part1/03-control-flow.md) |
| `string.format("%d", 2.5)` | error | error | `"2"` (truncates) | [L6](part1/06-strings.md) |
| `global` declarations | yes | no | no | [L2](part1/02-syntax-types.md) |
| `global` as a variable name | allowed in the default build (`LUA_COMPAT_GLOBAL`) | allowed | allowed | [L2](part1/02-syntax-types.md) |
| `local x <const>` / `<close>` | yes | yes | no (recent builds: `const x = …`) | [L2](part1/02-syntax-types.md) |
| Assigning a `for` control variable | **compile error** | allowed | allowed | [L3](part1/03-control-flow.md) |
| `continue` | no (`goto continue`) | no | builds from July 2026 on | [L3](part1/03-control-flow.md) |
| `#t` on tables with holes | often the *first* border | different border | different border | [L4](part1/04-tables-1.md) |
| `table.create(n, h)` | yes | no | no (`require "table.new"`) | [L5](part1/05-tables-2.md) |
| `table.pack` / `table.unpack` | yes | yes | no (`unpack` global) | [L5](part1/05-tables-2.md) |
| `table.move` | yes | yes | yes | [L5](part1/05-tables-2.md) |
| `utf8` library | yes | yes | no | [L6](part1/06-strings.md) |
| `utf8.offset` results | start **and end** byte | start byte | n/a | [L6](part1/06-strings.md) |
| `string.pack` / `unpack` | yes | yes | no (use FFI) | [L6](part1/06-strings.md) |
| `"\0"` inside a pattern set `[...]` | ok | ok | "malformed pattern" | [L7](part1/07-patterns.md) |
| Named varargs `function f(...t)` | yes | no | no | [L8](part1/08-functions.md) |
| Runtime error message for calling a nil global | `attempt to call a nil value (global 'f')` | same | `attempt to call global 'f' (a nil value)` | [L8](part1/08-functions.md) |
| `error(nil)` caught by `pcall` | `<no error object>` | `nil` | `nil` | below |
| `math.pow` | removed | present (5.3 compat in default build) | present | below |
| `setfenv`, `loadstring` | no | no | yes | below |
| `__len` / `__pairs` on tables | yes | yes | no (5.1 semantics) | below |
| `collectgarbage("generational")` | yes | yes | no | below |
| `collectgarbage("param", …)` | yes (new) | no | no | below |
| `a <= b` with only `__lt` defined | **error** (needs `__le`) | works (`LUA_COMPAT_LT_LE`) | works | [L10](part2/10-metatables.md) |
| `__eq` on objects with different metamethods | first operand's, else second's | same | only if both share the same `__eq` | [L10](part2/10-metatables.md) |
| Chains of `__call` | up to 15 objects | yes | no | [L10](part2/10-metatables.md) |
| `__name` in error messages, bit-operator metamethods | yes | yes | no | [L10](part2/10-metatables.md) |
| `__close` / `<close>` | yes | yes | no | [L10](part2/10-metatables.md), [L13](part2/13-errors.md) |
| `require` passes/returns the loader data (file path) | yes | yes | no (one value) | [L12](part2/12-modules.md) |
| Module searchers | `package.searchers` | `package.searchers` | `package.loaders` | [L12](part2/12-modules.md) |
| `assert(false, msg)` adds position | yes | yes | no | [L13](part2/13-errors.md) |
| Traceback frame names | `in global 'error'`, `in upvalue 'f'` | `in function 'error'`, `in upvalue 'f'` | `in function 'f'`, ends `[C]: at 0x…` | [L13](part2/13-errors.md) |
| `error(42)` (number) | number unchanged | number unchanged | converted to a positioned string | [L13](part2/13-errors.md) |
| `coroutine.running()` in main | main thread, `true` | main thread, `true` | `nil` | [L14](part2/14-coroutines.md) |
| `coroutine.close`, 4th `for` value (closing) | yes | yes | no | [L14](part2/14-coroutines.md) |
| `os.execute` result | `true\|nil, "exit", code` | same | raw status (`768`) | [L15](part2/15-stdlib.md) |
| `math.randomseed(42)` sequence | xoshiro256** | same as 5.5 | different (Tausworthe) | [L15](part2/15-stdlib.md) |
| `math.floor`/`ceil` result | integer | integer | float (printed without `.0`) | [L15](part2/15-stdlib.md) |
| Hidden loop locals in `debug.getlocal` | `(for state)` ×2, `(vararg table)` | `(for state)` ×3 | `(for index)`, `(for limit)`, `(for step)` | [L15](part2/15-stdlib.md) |
| `setpause` / `setstepmul` | removed | yes (deprecated) | yes | [L16](part2/16-gc.md) |
| Ephemeron tables | yes | yes | **no** (weak-key value keeps key alive) | [L16](part2/16-gc.md) |
| `__gc` on tables | yes | yes | **no** (userdata, `newproxy`, `ffi.gc`) | [L16](part2/16-gc.md) |

## Feature detection

Prefer detecting features to checking `_VERSION`. This script prints what is available:

```lua title="examples/99-version-diffs/features.lua"
--8<-- "examples/99-version-diffs/features.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/99-version-diffs/features.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/99-version-diffs/features.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/99-version-diffs/features.jit.expected"
    ```

Note `math.pow` on Lua 5.4: it was deprecated in 5.3, but the default 5.4 build
still defines `LUA_COMPAT_5_3`, which keeps it. Lua 5.5 has no such switch, so code
using `math.pow` breaks on 5.5. Use `x ^ y`.

## `error(nil)`

Lua 5.5 replaces a `nil` error object with a string, so `pcall` never returns
`false, nil`:

```lua title="examples/99-version-diffs/error_nil.lua"
--8<-- "examples/99-version-diffs/error_nil.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/99-version-diffs/error_nil.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/99-version-diffs/error_nil.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/99-version-diffs/error_nil.jit.expected"
    ```

## Garbage collector modes

```lua title="examples/99-version-diffs/gc_modes.lua"
--8<-- "examples/99-version-diffs/gc_modes.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/99-version-diffs/gc_modes.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/99-version-diffs/gc_modes.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/99-version-diffs/gc_modes.jit.expected"
    ```

!!! info "Surprise: the standalone `lua` runs a generational GC"
    The first call returns the *previous* mode, and it says `generational`. The
    library default is incremental, but `lua.c` in both 5.4 and 5.5 switches the
    collector to generational mode at start-up. A host application that embeds
    Lua gets the incremental collector unless it asks otherwise, so GC
    behaviour measured with the `lua` command can differ from your embedded app.
    In 5.5, GC parameters moved to `collectgarbage("param", name [, value])`.

## `__len` and `__pairs`

```lua title="examples/99-version-diffs/meta52.lua"
--8<-- "examples/99-version-diffs/meta52.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/99-version-diffs/meta52.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/99-version-diffs/meta52.jit.expected"
    ```

LuaJIT follows Lua 5.1 here: `__len` is ignored for tables and `__pairs` does not
exist (unless LuaJIT is built with `LUAJIT_ENABLE_LUA52COMPAT`).

## LuaJIT 2.1 syntax backports

In July 2026 (LuaJIT `2.1.1784535649` and later), Mike Pall backported a set of
syntax extensions from the upcoming LuaJIT 3.0 into the rolling 2.1 branch:
bitwise operators, `!`, `&&`, `||`, `!=`, the ternary `?:`, safe navigation `?.`,
nil-coalescing `??`, compound assignment (`+=`, `..=`, …), `continue`, `const`,
short function expressions `|a, b| -> a + b`, and underscores in numbers.
**Not** backported: `//`, bit-operator metamethods, and named varargs.

```lua title="examples/99-version-diffs/luajit_syntax.lua"
--8<-- "examples/99-version-diffs/luajit_syntax.lua"
```

```text
--8<-- "examples/99-version-diffs/luajit_syntax.expected"
```

!!! danger "Do not use these in portable code"
    None of this is valid PUC-Rio Lua, and LuaJIT builds older than July 2026
    reject it (including many distribution packages and the LuaJIT bundled with
    Neovim and OpenResty releases). Bytecode that uses the new bit operators can
    only be loaded by LuaJIT 2.1.1784535649 or newer. The course uses this syntax
    only in examples marked `-- targets: jit`.

## Lua 5.5 changes not covered yet

From the Lua 5.5 readme and manual §8, still to be demonstrated in later parts:
incremental major collections, more compact arrays (about 60% less memory for
large arrays), external strings, `luaL_openselectedlibs` / `luaL_makeseed`,
`lua_newstate` taking a seed argument. (The 15-object limit on `__call` chains, the
`"param"` GC option and `table.create` are covered in Lessons 10, 16 and 17.)
