# 1. Why Lua: Tiny, Fast, Embeddable

--8<-- "includes/badges/01-why-lua.md"

!!! abstract "What you will be able to do after this lesson"
    - Explain where Lua fits next to C++, Rust and Python, and why so many hosts embed it.
    - Tell PUC-Rio Lua 5.5, Lua 5.4 and LuaJIT apart, at the shell and from inside a script.
    - Use the REPL, run scripts, read command-line arguments and process standard input.

## Intuition: a language designed to be a guest

Most languages want to be the *host*: they own `main()`, the build system and the
package manager. Lua was designed from day one to be a **guest**. Its whole
implementation is about 32 000 lines of portable ANSI C, the interpreter and
standard library compile into a binary of a few hundred kilobytes, and the C API
lets a host program push values in, call Lua functions, and expose its own
functions back.

That design choice explains everything else about Lua:

| Design goal | Consequence you will see in this course |
|---|---|
| Small enough to embed anywhere | One data structure (the **table**) does the work of arrays, maps, objects, modules and namespaces. |
| Host decides the policy | The standard library is deliberately thin; the host (Neovim, mpv, Redis, your C++ app) supplies the interesting APIs. |
| Safe to hand to users | Scripts can be sandboxed by controlling which globals they see. |
| Fast enough for inner loops | A register-based VM, and LuaJIT, one of the fastest dynamic-language JITs ever built. |

If you have written plugins for a C++ media framework, think of Lua as a
**scripting layer you can bolt onto your own engine** in an afternoon, with a
language your users can learn in a weekend.

!!! note "For C++/Rust developers"
    Lua sits in the same slot that a plugin ABI or a config DSL would occupy in a
    C++ or Rust project. Instead of designing a struct-based plugin interface and
    a TOML schema, you expose a handful of C functions and let users write
    real code. In Part 3 you will embed Lua in C++ and in Rust (via `mlua`).

### Who embeds Lua

- **Neovim**: configuration and plugins (LuaJIT).
- **mpv**: user scripts for key bindings, OSD and playlists (Lua 5.1 or LuaJIT, depending on the build).
- **Redis** and **Valkey**: atomic server-side scripts (Lua 5.1).
- **OpenResty / Nginx**: request handling at the edge (LuaJIT).
- **LÖVE**: complete 2D games (LuaJIT).
- **Wireshark**, **Roblox** (Luau, a Lua derivative), **Adobe Lightroom**, many game engines and network devices.

Notice that a lot of that list runs **LuaJIT, which implements Lua 5.1 plus a few
extensions**. That is why every lesson here is tested on three interpreters.

## The three interpreters in this course

| Interpreter | Language level | Binary used in this course | Where you meet it |
|---|---|---|---|
| PUC-Rio Lua 5.5 | 5.5 (latest, released 2025) | `lua5.5` | New standalone code, new embeddings |
| PUC-Rio Lua 5.4 | 5.4 | `lua5.4` | Most current embeddings and distro packages |
| LuaJIT 2.1 | 5.1 + extensions | `luajit` | Neovim, OpenResty, LÖVE, games |

See [Setup](../setup.md) to build all three. The rest of this lesson assumes they
are on your `PATH`.

## Worked example 1: Hello, and which Lua am I?

```lua title="examples/01-why-lua/hello.lua"
--8<-- "examples/01-why-lua/hello.lua"
```

Run it with each interpreter: `lua5.5 hello.lua`, `lua5.4 hello.lua`, `luajit hello.lua`.

=== "Lua 5.5"
    ```text
    --8<-- "examples/01-why-lua/hello.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/01-why-lua/hello.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/01-why-lua/hello.jit.expected"
    ```

`_VERSION` is a global string holding the **language** version, not the release.
LuaJIT reports `Lua 5.1` because that is the language it implements. To tell
LuaJIT apart at run time, check for its `jit` library:

```lua title="examples/01-why-lua/which_lua.lua"
--8<-- "examples/01-why-lua/which_lua.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/01-why-lua/which_lua.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/01-why-lua/which_lua.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/01-why-lua/which_lua.jit.expected"
    ```

!!! info "Version difference: integers"
    Lua 5.3 introduced a real 64-bit **integer subtype** alongside floats. Lua 5.4
    and 5.5 keep it. LuaJIT (5.1 semantics) has only doubles, plus FFI-boxed
    64-bit integers such as `1LL`. Lesson 2 shows the visible effects.

## Worked example 2: the REPL

Type `lua5.5` with no arguments to get an interactive prompt. Since Lua 5.3 the
REPL prints the value of an expression directly; in LuaJIT (and Lua 5.1) you
prefix it with `=`:

```console
$ lua5.5
Lua 5.5.1  Copyright (C) 1994-2026 Lua.org, PUC-Rio
> 1 + 1
2
> 7 // 2
3
> ^D

$ luajit
LuaJIT 2.1.1794386141 -- Copyright (C) 2005-2026 Mike Pall. https://luajit.org/
JIT: ON SSE3 SSE4.1 BMI2 fold cse dce fwd dse narrow loop abc sink fuse
> = 1 + 1
2
```

Useful flags (the same on all three):

| Flag | Meaning |
|---|---|
| `lua -i script.lua` | Run the script, then stay in the REPL with its globals available. |
| `lua -e 'print(2^10)'` | Execute a string. |
| `lua -l mod` | `require("mod")` before running. |
| `lua -` | Read the program from stdin. |
| `lua -v` | Print the version. |

!!! tip "Line editing (history and arrow keys)"
    - **Lua 5.5**: `lua.c` now loads readline *dynamically* at start-up. It looks
      for `libreadline.so`, which on Ubuntu comes with `libreadline-dev`. Without
      that package, point it at the runtime library:
      `export LUA_READLINELIB=libreadline.so.8`.
    - **Lua 5.4**: line editing must be compiled in (`make linux-readline`), or wrap
      the REPL: `rlwrap lua5.4`.
    - **LuaJIT** has no readline support; use `rlwrap luajit`.

## Worked example 3: scripts, arguments and stdin

A script's command-line arguments arrive in the global table `arg`.
`arg[0]` is the script name and `arg[1]` … `arg[#arg]` are the arguments:

```lua title="examples/01-why-lua/args.lua"
--8<-- "examples/01-why-lua/args.lua"
```

Running `lua5.5 args.lua` with no arguments prints:

```text
--8<-- "examples/01-why-lua/args.expected"
```

Try `lua5.5 args.lua one "two words"` yourself. Inside the main chunk the same
arguments are also available as the vararg expression `...` (Lesson 8).

Now a small "real" tool: count log levels in text arriving on stdin. Do not worry
about `line:match` yet; patterns are Lesson 7.

```lua title="examples/01-why-lua/count_lines.lua"
--8<-- "examples/01-why-lua/count_lines.lua"
```

With this input file (`lua5.5 count_lines.lua < count_lines.input`):

```text title="count_lines.input"
--8<-- "examples/01-why-lua/count_lines.input"
```

Output:

```text
--8<-- "examples/01-why-lua/count_lines.expected"
```

Three idioms already appear here, and you will use them constantly:

1. `local` for every variable (Lesson 2 explains why).
2. `counts[level] = (counts[level] or 0) + 1`: a table used as a counter, with `or` supplying a default.
3. `for x in iterator do`: the generic `for` (Lesson 3).

!!! note "For C++/Rust developers"
    There is no compile step and no `main`. A file is a **chunk**: it runs top to
    bottom, and is itself compiled into an anonymous function. `luac5.5 -l file.lua`
    lists the VM bytecode, which is a nice way to peek under the hood.

## Hands-on exercises

??? example "Exercise 1: interpreter report"
    Write a script that prints the language version, whether it runs on LuaJIT,
    whether the `//` operator is available, and whether the `utf8` library exists.
    Hint: `load("return 7 // 2")` returns `nil` (plus an error message) when the
    code does not compile.

    ??? success "Solution"
        ```lua
        --8<-- "examples/01-why-lua/ex1_versions.lua"
        ```
        === "Lua 5.5"
            ```text
            --8<-- "examples/01-why-lua/ex1_versions.expected"
            ```
        === "Lua 5.4"
            ```text
            --8<-- "examples/01-why-lua/ex1_versions.5.4.expected"
            ```
        === "LuaJIT 2.1"
            ```text
            --8<-- "examples/01-why-lua/ex1_versions.jit.expected"
            ```

??? example "Exercise 2: greeter"
    Read names from stdin, one per line, skip empty lines, and greet each one with
    a running visitor number. Finish with the total.

    ??? success "Solution"
        ```lua
        --8<-- "examples/01-why-lua/ex2_greet.lua"
        ```
        Input:
        ```text
        --8<-- "examples/01-why-lua/ex2_greet.input"
        ```
        Output:
        ```text
        --8<-- "examples/01-why-lua/ex2_greet.expected"
        ```

??? example "Exercise 3: powers of two"
    Print `i`, `2^i` and `1 << i` for even `i` from 0 to 10. Why does the second
    column differ between Lua 5.4/5.5 and LuaJIT? Then write a variant for LuaJIT
    builds that do not understand `<<`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/01-why-lua/ex3_powers.lua"
        ```
        === "Lua 5.5 / 5.4"
            ```text
            --8<-- "examples/01-why-lua/ex3_powers.expected"
            ```
        === "LuaJIT 2.1"
            ```text
            --8<-- "examples/01-why-lua/ex3_powers.jit.expected"
            ```
        `^` always produces a **float** in Lua 5.3+, and floats with an integral
        value print with `.0`. LuaJIT has only one number type, so it prints `1`.
        `<<` works on integers and produces an integer.

        The bitwise operators are standard since Lua 5.3. LuaJIT only gained them
        in July 2026, when syntax extensions from LuaJIT 3.0 were backported to
        the rolling 2.1 branch (see [Version Differences](../version-differences.md#luajit-21-syntax-backports)).
        Older LuaJIT builds, which many Neovim and OpenResty releases bundle, need
        the `bit` library:
        ```lua
        --8<-- "examples/01-why-lua/ex3_powers_jit.lua"
        ```
        ```text
        --8<-- "examples/01-why-lua/ex3_powers_jit.expected"
        ```

## Quiz

??? question "Q1. Why does Lua keep its standard library so small?"
    Because it is designed to be embedded: the **host** supplies the
    domain-specific APIs and decides what scripts may do. A small core also keeps
    the interpreter tiny and portable.

??? question "Q2. What does `_VERSION` print on LuaJIT 2.1, and why?"
    `Lua 5.1`. `_VERSION` reports the language level, and LuaJIT implements Lua 5.1
    (plus selected 5.2 features and its own extensions). Check `type(jit) == "table"`
    to detect LuaJIT.

??? question "Q3. How do you evaluate `2 + 3` in the LuaJIT REPL?"
    Type `= 2 + 3` (or `print(2 + 3)`). Lua 5.3+ REPLs print expression values
    without the `=`.

??? question "Q4. Where are a script's command-line arguments?"
    In the global table `arg` (`arg[0]` is the script name, `arg[1]` onwards the
    arguments) and as the vararg expression `...` in the main chunk.

??? question "Q5. Name three widely used programs that embed LuaJIT or Lua 5.1 rather than Lua 5.4/5.5."
    Any three of: Neovim, OpenResty, LÖVE, Redis (5.1), mpv (often LuaJIT or 5.1),
    many game engines. This is why the course tests every example on LuaJIT too.
