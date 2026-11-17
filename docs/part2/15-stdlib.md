# 15. The Standard Library Tour: `io`, `os`, `math`, `debug`

--8<-- "includes/badges/15-stdlib.md"

!!! abstract "What you will be able to do after this lesson"
    - Read and write files and standard streams with `io`, including read formats and seeking.
    - Use `os` for time, dates, environment variables and child processes, knowing its portability limits.
    - Use `math`, and know why random sequences are not portable.
    - Inspect running code with `debug`: function info, locals, upvalues and hooks.

## Intuition: a deliberately thin layer over ANSI C

Lua's standard library is whatever ISO C provides, and no more: `io` wraps
`FILE*`, `os` wraps `time`, `clock`, `system`, `getenv` and `remove`, `math` wraps
`<math.h>`. There is no directory listing, no sockets, no threads, no regex. That
is not an oversight: Lua must compile on any C compiler, and hosts (or libraries
such as LuaFileSystem and luasocket) provide the rest.

!!! note "For C++/Rust developers"
    `io.open` is `fopen`, `f:read("l")` is `fgets` without the newline,
    `f:seek` is `fseek`/`ftell`, `os.execute` is `system()`, and `io.popen` is
    `popen`. For `std::filesystem` or `std::fs::read_dir` equivalents you need
    LuaFileSystem (`lfs`), or the host's API (`vim.uv` in Neovim, `utils` in mpv).

## Files

```lua title="examples/15-stdlib/io_files.lua"
--8<-- "examples/15-stdlib/io_files.lua"
```

```text
--8<-- "examples/15-stdlib/io_files.expected"
```

| Read format | Meaning |
|---|---|
| `"l"` | next line without the newline (default) |
| `"L"` | next line including the newline |
| `"n"` | a number (returns `nil` if the text is not a number) |
| `"a"` | the rest of the file (`""` at end of file, never `nil`) |
| `k` (a number) | up to `k` bytes; `0` tests for end of file |

The `"*l"`/`"*a"` spellings from Lua 5.1 still work in 5.4/5.5 and LuaJIT; the
short forms work everywhere too.

## Standard streams

```lua title="examples/15-stdlib/io_streams.lua"
--8<-- "examples/15-stdlib/io_streams.lua"
```

Input (`io_streams.input`):

```text
--8<-- "examples/15-stdlib/io_streams.input"
```

```text
--8<-- "examples/15-stdlib/io_streams.expected"
```

`print` adds tabs and a newline and calls `tostring`; `io.write` writes its
arguments as they are (strings and numbers only), which is what you want for
generated output.

## `os`: time, environment, processes

```lua title="examples/15-stdlib/os_basics.lua"
--8<-- "examples/15-stdlib/os_basics.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/15-stdlib/os_basics.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/15-stdlib/os_basics.jit.expected"
    ```

`os.date` takes `strftime` formats; a leading `!` means UTC, and `"*t"` returns a
table. `os.time(table)` goes the other way, interpreting the table as **local**
time. `os.clock()` is CPU time, useful for benchmarks (Lesson 17).

### Exit statuses changed in Lua 5.2

```lua title="examples/15-stdlib/os_execute.lua"
--8<-- "examples/15-stdlib/os_execute.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/15-stdlib/os_execute.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/15-stdlib/os_execute.jit.expected"
    ```

Lua 5.2+ returns `true|nil, "exit"|"signal", code`. LuaJIT keeps the 5.1
behaviour: `os.execute` returns the raw `wait` status (`768` = exit code 3 shifted
left by 8), and closing a `popen` file just returns `true`. Scripts that check
`os.execute(cmd) == 0` work on LuaJIT but always fail on 5.4.

## `math`

```lua title="examples/15-stdlib/math_tour.lua"
--8<-- "examples/15-stdlib/math_tour.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/15-stdlib/math_tour.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/15-stdlib/math_tour.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/15-stdlib/math_tour.jit.expected"
    ```

There is no `math.round`; see Exercise 4. `math.floor` and `math.ceil` return
integers on 5.4/5.5 when the result fits. Also available: `math.tointeger`,
`math.type`, `math.ult`, `math.maxinteger`/`mininteger` (5.3+).

### Random numbers

```lua title="examples/15-stdlib/random.lua"
--8<-- "examples/15-stdlib/random.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/15-stdlib/random.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/15-stdlib/random.jit.expected"
    ```

Lua 5.4+ uses the xoshiro256\*\* generator and seeds it randomly at start-up;
LuaJIT uses its own Tausworthe generator with a fixed default seed. A seed
reproduces a sequence only on the same implementation, and for LuaJIT not even
reliably across machines: with the same LuaJIT commit, `math.random(1, 100)` after
`math.randomseed(42)` gave `96 1 54` on the machine that wrote this course and
`96 1 55` on the GitHub Actions runner. If tests or replays need
identical numbers everywhere, ship your own generator (Exercise 5).

## `debug`: introspection

The `debug` library breaks the language's abstractions (it can read any local and
change any upvalue). Use it for tools such as debuggers, profilers and error
reporters, not for program logic.

```lua title="examples/15-stdlib/debug_info.lua"
--8<-- "examples/15-stdlib/debug_info.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/15-stdlib/debug_info.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/15-stdlib/debug_info.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/15-stdlib/debug_info.jit.expected"
    ```

!!! info "Surprise: internal locals differ in every version"
    The names in parentheses are hidden VM slots. Lua 5.5 shows a
    `(vararg table)` for every variadic function (its new vararg implementation) and
    uses two `(for state)` slots per numeric loop; 5.4 uses three; LuaJIT names them
    `(for index)`, `(for limit)`, `(for step)`. Tools must skip names starting with `(`.

Hooks run a function on every call, return, line or N instructions:

```lua title="examples/15-stdlib/debug_hook.lua"
--8<-- "examples/15-stdlib/debug_hook.lua"
```

```text
--8<-- "examples/15-stdlib/debug_hook.expected"
```

!!! warning "Hooks and LuaJIT"
    Hooks are expensive: a line hook calls a Lua function for every line executed.
    In PUC Lua hooks are per coroutine (`debug.sethook(co, f, mask)`); LuaJIT has
    one global hook and its documentation lists small debug API differences
    (no per-coroutine hooks, no tail call counting). Remove hooks as soon as you are done.

## Hands-on exercises

??? example "Exercise 1: CSV summary"
    Write a small CSV file to a temporary path, then report the number of files
    and total seconds per codec, sorted by codec.

    ??? success "Solution"
        ```lua
        --8<-- "examples/15-stdlib/ex1_csv.lua"
        ```
        ```text
        --8<-- "examples/15-stdlib/ex1_csv.expected"
        ```

??? example "Exercise 2: timestamps and durations"
    Format a Unix time as ISO-8601 UTC, and a number of seconds as `1d 1h 1m 1s`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/15-stdlib/ex2_iso.lua"
        ```
        ```text
        --8<-- "examples/15-stdlib/ex2_iso.expected"
        ```

??? example "Exercise 3: call counter"
    Use a `"c"` hook to count how many times each named Lua function is called.

    ??? success "Solution"
        ```lua
        --8<-- "examples/15-stdlib/ex3_callcount.lua"
        ```
        ```text
        --8<-- "examples/15-stdlib/ex3_callcount.expected"
        ```

??? example "Exercise 4: round, clamp, lerp"
    Implement the math helpers every media or game project needs.

    ??? success "Solution"
        ```lua
        --8<-- "examples/15-stdlib/ex4_mathutil.lua"
        ```
        ```text
        --8<-- "examples/15-stdlib/ex4_mathutil.expected"
        ```

??? example "Exercise 5: a portable PRNG"
    Write a seedable random generator that gives the same numbers on Lua 5.5, 5.4
    and LuaJIT, and use it for a reproducible shuffle.

    ??? success "Solution"
        ```lua
        --8<-- "examples/15-stdlib/ex5_lcg.lua"
        ```
        ```text
        --8<-- "examples/15-stdlib/ex5_lcg.expected"
        ```
        All intermediate values stay below 2^53, so doubles (LuaJIT) and 64-bit
        integers (5.4/5.5) compute exactly the same results.

## Quiz

??? question "Q1. What does `f:read(\"a\")` return at end of file? And `f:read(\"l\")`?"
    `"a"` returns an empty string; `"l"` returns `nil`.

??? question "Q2. Why does `if os.execute(cmd) == 0 then` fail on Lua 5.4 but work on LuaJIT?"
    Lua 5.2+ returns `true`/`nil`, a string and the exit code; LuaJIT returns the
    raw numeric status like Lua 5.1.

??? question "Q3. How do you format a time in UTC with `os.date`?"
    Start the format with `!`, e.g. `os.date("!%Y-%m-%dT%H:%M:%SZ", t)`.

??? question "Q4. Will `math.randomseed(42)` give the same sequence on Lua 5.4 and LuaJIT?"
    No. They use different generators; seeds are only reproducible within one implementation.

??? question "Q5. Why should library code avoid the `debug` library?"
    It bypasses encapsulation (locals, upvalues, metatables), is slow, and its
    details (such as hidden local names) differ between versions. Keep it for tooling.
