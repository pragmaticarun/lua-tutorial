# 12. Modules and `require`

--8<-- "includes/badges/12-modules.md"

!!! abstract "What you will be able to do after this lesson"
    - Write modules in the standard "return a table" style, with private helpers.
    - Explain how `require` searches (`package.path`, `?` templates, submodules) and caches (`package.loaded`).
    - Register modules without files (`package.preload`, custom searchers), as embedding hosts do.
    - Keep modules from leaking globals, including with Lua 5.5 declarations.

## Intuition: a module is a function that runs once

A Lua module is just a **chunk** (a file) that returns a value, usually a table of
functions. `require("name")`:

1. returns `package.loaded["name"]` if it is already there (the cache);
2. otherwise asks a list of **searchers** to find a loader: first
   `package.preload`, then Lua files along `package.path`, then C libraries
   along `package.cpath`;
3. runs the loader once and stores its result in `package.loaded["name"]`.

Everything a module wants to keep private is simply a `local` in that file.

!!! note "For C++/Rust developers"
    There is no compile-time module system: `require` is an ordinary function
    that runs at run time, and a module's "exports" are whatever table it
    returns. The cache in `package.loaded` makes modules behave like singletons
    (like a Rust `static` initialised on first use). Search paths work like
    `LD_LIBRARY_PATH`: a semicolon-separated list of templates.

## Writing and using a module

```lua title="examples/12-modules/mediainfo.lua"
--8<-- "examples/12-modules/mediainfo.lua"
```

A submodule lives in a directory named after its parent:

```lua title="examples/12-modules/mediainfo/codecs.lua"
--8<-- "examples/12-modules/mediainfo/codecs.lua"
```

```lua title="examples/12-modules/use_modules.lua"
--8<-- "examples/12-modules/use_modules.lua"
```

```text
--8<-- "examples/12-modules/use_modules.expected"
```

!!! tip "The `-- module` header"
    Files marked `-- module` are libraries. The course's test runner does not run
    them on their own; they are tested through the examples that `require` them.

## How `require` finds files

`package.path` is a list of templates separated by `;`. For
`require("mediainfo.codecs")`, Lua replaces dots with the directory separator and
substitutes the result for each `?`:

```lua title="examples/12-modules/searchpath.lua"
--8<-- "examples/12-modules/searchpath.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/12-modules/searchpath.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/12-modules/searchpath.jit.expected"
    ```

The defaults come from compile-time constants and the environment variables
`LUA_PATH_5_5` / `LUA_PATH_5_4` / `LUA_PATH` (and `LUA_CPATH…`). A `;;` inside the
variable stands for the default path, so `export LUA_PATH="./lib/?.lua;;"`
prepends a directory. Note that the defaults point at `/usr/local/share/lua/5.x`
even when the interpreter is installed elsewhere (such as `/opt`), because they
are compiled in.

## Modules without files: `package.preload`

Applications that embed Lua often ship scripts inside the binary. `package.preload`
maps a module name to a loader function, and is consulted before any file:

```lua title="examples/12-modules/preload.lua"
--8<-- "examples/12-modules/preload.lua"
```

```text
--8<-- "examples/12-modules/preload.expected"
```

## Reloading

Because the cache is a plain table, you can clear an entry and require again.
Existing references keep pointing at the old table, which is why hot reload
needs care:

```lua title="examples/12-modules/reload.lua"
--8<-- "examples/12-modules/reload.lua"
```

```text
--8<-- "examples/12-modules/reload.expected"
```

## Avoiding global leaks

A forgotten `local` inside a module creates a global visible to the whole program:

```lua title="examples/12-modules/leaky.lua"
--8<-- "examples/12-modules/leaky.lua"
```

```lua title="examples/12-modules/leak_check.lua"
--8<-- "examples/12-modules/leak_check.lua"
```

```text
--8<-- "examples/12-modules/leak_check.expected"
```

Tools such as luacheck (Lesson 28) catch this statically. On Lua 5.5, starting
the module with `global<const> *` makes it a compile error (Exercise 4).

## Version differences

The arguments `require` passes to the module chunk, and what it returns, changed
in Lua 5.4. The table of searchers was also renamed in 5.2:

```lua title="examples/12-modules/args_module.lua"
--8<-- "examples/12-modules/args_module.lua"
```

```lua title="examples/12-modules/require_args.lua"
--8<-- "examples/12-modules/require_args.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/12-modules/require_args.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/12-modules/require_args.jit.expected"
    ```

| | Lua 5.4 / 5.5 | LuaJIT / 5.1 |
|---|---|---|
| Arguments to the module chunk | name, file path | name only |
| Results of `require` | module, loader data (the path) | module |
| Searcher list | `package.searchers` | `package.loaders` |
| `module()` function | removed | present (deprecated style: avoid) |

!!! warning "Watch out for `print(require 'x')`"
    Because `require` returns two values on 5.4+, it can add an unexpected extra
    argument when used as the last argument in a call. Wrap it in parentheses.

## Hands-on exercises

??? example "Exercise 1: a units module"
    Write a module `units` with public `bytes(n)` and `bitrate(bps)` functions and
    a private scaling helper, then use it from another file.

    ??? success "Solution"
        ```lua title="examples/12-modules/ex/units.lua"
        --8<-- "examples/12-modules/ex/units.lua"
        ```
        ```lua title="examples/12-modules/ex1_units.lua"
        --8<-- "examples/12-modules/ex1_units.lua"
        ```
        ```text
        --8<-- "examples/12-modules/ex1_units.expected"
        ```

??? example "Exercise 2: lazy submodules"
    Write `lazy(prefix)` returning a table where `t.name` requires
    `prefix .. "." .. name` on first access only.

    ??? success "Solution"
        ```lua
        --8<-- "examples/12-modules/ex2_lazy.lua"
        ```
        ```text
        --8<-- "examples/12-modules/ex2_lazy.expected"
        ```

??? example "Exercise 3: a custom searcher"
    Make `require` load modules from a table of source strings (as a C++ host would
    for scripts compiled into the binary). Make it work on 5.4/5.5 and LuaJIT.

    ??? success "Solution"
        ```lua
        --8<-- "examples/12-modules/ex3_searcher.lua"
        ```
        ```text
        --8<-- "examples/12-modules/ex3_searcher.expected"
        ```
        A searcher returns a loader function, or a string explaining why it found
        nothing; `require` concatenates those strings into its error message.

??? example "Exercise 4: a leak-proof module (Lua 5.5)"
    Use a Lua 5.5 global declaration so that the leaky module fails to compile.

    ??? success "Solution"
        ```lua
        --8<-- "examples/12-modules/ex4_strict_module.lua"
        ```
        ```text
        --8<-- "examples/12-modules/ex4_strict_module.expected"
        ```

## Quiz

??? question "Q1. A module prints a message in its top-level code. How many times does it appear if three files require it?"
    Once. After the first load the result is cached in `package.loaded`.

??? question "Q2. Which file does `require(\"a.b\")` try with `package.path = \"./?.lua\"`?"
    `./a/b.lua`: dots become directory separators before substitution.

??? question "Q3. How can a host application provide a module that has no file on disk?"
    Put a loader function in `package.preload[name]`, or add a custom searcher to
    `package.searchers` (`package.loaders` on 5.1/LuaJIT).

??? question "Q4. What does `;;` mean in `LUA_PATH`?"
    It is replaced by the default path, so you can add directories without losing
    the standard locations.

??? question "Q5. What is the second result of `require` in Lua 5.4, and why can it surprise you?"
    The loader data, for file modules the file path. `f(require "x")` passes it
    as an extra argument to `f`.
