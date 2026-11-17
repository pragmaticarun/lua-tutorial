# 18. LuaJIT: The Trace Compiler

--8<-- "includes/badges/18-luajit.md"

!!! abstract "What you will be able to do after this lesson"
    - Explain how a tracing JIT decides what to compile, and what a trace is.
    - Read `-jv` and `-jdump` output, from the command line or from inside a script.
    - Recognise trace aborts (NYI), blacklisting and stitching, and fix the common causes.
    - Write code that runs on LuaJIT (Lua 5.1 dialect) and on Lua 5.4/5.5.
    - Know why the new LuaJIT 2.1-branch syntax is not portable.

## Intuition: record what actually happens, then compile that

LuaJIT starts every program in a fast interpreter (hand-written assembly). It
counts how often each loop runs and each function is called. When a counter
reaches the `hotloop` threshold (56 by default), it **records** the next
execution: every bytecode actually executed, with the types and branch
directions actually seen. That linear recording, the **trace**, is turned into
SSA IR, optimised and compiled to machine code. Assumptions made while recording
(this value is a number, this branch goes left) become **guards**; if a guard fails
at run time the trace *exits* back to the interpreter, and an exit that is taken
often (`hotexit`, 10 times) gets its own **side trace**.

!!! note "For C++/Rust developers"
    A method JIT (V8, HotSpot, .NET) compiles whole functions. A trace JIT
    compiles hot *paths*, inlining across function calls automatically. This is
    why LuaJIT gets close to C speed on numeric loops, and also why one
    uncompilable operation in a hot loop costs you the whole loop: the trace
    aborts and that code stays in the interpreter.

## The `jit` module

```lua title="examples/18-luajit/jit_info.lua"
--8<-- "examples/18-luajit/jit_info.lua"
```

```text
--8<-- "examples/18-luajit/jit_info.expected"
```

`luajit -O3` (default) to `-O0` toggles the optimisation passes listed above;
`jit.opt.start("hotloop=10")` changes the parameters at run time.

## Watching traces: `-jv`

On the command line, `luajit -jv script.lua` prints one line per trace event.
The same module (`jit.v`) can be switched on from inside a script, which is how
this example captures its own trace log:

```lua title="examples/18-luajit/trace_log.lua"
--8<-- "examples/18-luajit/trace_log.lua"
```

```text
--8<-- "examples/18-luajit/trace_log.expected"
```

Reading the log:

- `[TRACE 1 trace_log.lua:7 loop]`: trace 1 starts at line 7 and ends by looping
  back to its own start: the best case.
- Trace 2 includes the call to `tostring`. LuaJIT 2.1 can also **stitch** around
  C functions it cannot compile (`stitch string.gsub` in `-jv` output): the trace
  ends, the C function runs, and a new trace continues afterwards.
- `TRACE --- ... NYI: bytecode FNEW`: recording **aborted**. Creating a closure
  is "not yet implemented" in the JIT. After a few failed attempts LuaJIT
  **blacklists** that loop and stops trying: it runs in the interpreter forever.
- `[TRACE 4 (3/5) trace_log.lua:16 -> 3]`: a **side trace** attached to exit 5 of
  trace 3 (the `else` branch), which jumps back into trace 3 when done.

## Looking inside: `-jdump`

`-jdump` shows the bytecode, the IR and the machine code of each trace. The IR
is the interesting part; the machine code depends on your CPU.

```lua title="examples/18-luajit/trace_dump.lua"
--8<-- "examples/18-luajit/trace_dump.lua"
```

```text
--8<-- "examples/18-luajit/trace_dump.expected"
```

- Instructions marked `>` are **guards**: `SLOAD #3 T` checks that `s` is still a
  number when the trace is entered; `LE 0006 +1000` is the loop condition.
- The loop counter is narrowed to an `int`, while `s` is a `num` (double): LuaJIT
  has no integer subtype, so arithmetic on Lua values is floating point unless the
  compiler can prove it fits an integer.
- `i * 2` became `ADD 0002 0002` (strength reduction), and everything before
  `LOOP` is the first iteration, peeled so that invariant work is hoisted out
  of the loop body that follows.

## What aborts traces

Ask LuaJIT itself, with `jit.attach` and the error table in `jit.vmdef`:

```lua title="examples/18-luajit/trace_events.lua"
--8<-- "examples/18-luajit/trace_events.lua"
```

```text
--8<-- "examples/18-luajit/trace_events.expected"
```

!!! warning "`jit.attach` keeps one handler per event"
    Attaching a `"trace"` handler replaces any other, including the one behind
    `-jv`. Detach by calling `jit.attach(sameFunction)` with no event name; passing
    a different function does nothing.

Common causes of aborts and slow paths in LuaJIT 2.1 (`jit.vmdef.traceerr` lists every abort message your build can produce):

| Pattern | Why it hurts | Fix |
|---|---|---|
| Closures created in hot loops (`FNEW`) | NYI: the loop is never compiled | Hoist the function; pass state as arguments |
| Many C functions that are not "fast functions" | Each one ends the trace (stitching) | Prefer the built-ins the JIT knows, or the FFI |
| Mixed types in one variable or array | Guards fail, side traces multiply | Keep arrays homogeneous (Exercise 4) |
| Unbiased branches in tight loops | Side trace per branch, more exits | Use arithmetic or table lookups where it is natural |
| `pairs` on huge hash tables, `next` | Slower than array loops | Use arrays (`for i = 1, #t`) for hot data |
| Line/count hooks, `debug.*` in hot code | Hooks force instruction-by-instruction dispatch; `debug.*` is not compiled | Keep instrumentation out of hot paths and benchmarks |

## LuaJIT is Lua 5.1 (plus extensions)

LuaJIT implements the Lua 5.1 language and library, with a few 5.2 features
(`goto`, `\u{...}` escapes, `load` with mode and environment arguments) and its
own extensions (`bit`, `ffi`, `jit`, `table.new`, `table.clear`, `string.buffer`). Detect features instead of
checking `_VERSION`:

```lua title="examples/18-luajit/dialect.lua"
--8<-- "examples/18-luajit/dialect.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/18-luajit/dialect.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/18-luajit/dialect.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/18-luajit/dialect.jit.expected"
    ```

The big differences for real code:

- **Numbers**: all doubles. Integers are exact only up to 2^53; for 64-bit values
  use FFI `int64_t`/`uint64_t` cdata (`1LL`, Lesson 19).
- **No `_ENV`**: sandboxing uses `setfenv`/`getfenv`.
- **No integer division, bit operators or `<close>`** in the default dialect;
  use `math.floor(a / b)`, the `bit` library and explicit cleanup.
- **`unpack` is a global**, `table.pack`/`table.unpack` are missing (unless built
  with `LUAJIT_ENABLE_LUA52COMPAT`).
- Library differences seen in Part 2: `__gc` only on userdata, no ephemerons,
  `os.execute` returns a raw status, different `math.random`.

## The new syntax in the 2.1 branch: a caveat

```lua title="examples/18-luajit/syntax_probe.lua"
--8<-- "examples/18-luajit/syntax_probe.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/18-luajit/syntax_probe.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/18-luajit/syntax_probe.jit.expected"
    ```

In July 2026 Mike Pall backported a batch of LuaJIT 3.0 syntax to the rolling
2.1 branch (see the [cheat sheet](../version-differences.md#luajit-21-syntax-backports)).
It is tempting, but:

- It is **not Lua**: no other implementation, linter, formatter or language
  server accepts it.
- LuaJIT builds older than July 2026, including those bundled with most Neovim,
  OpenResty and distribution releases, reject it with a syntax error.
- `//` is still not an operator in LuaJIT, so even the overlap with 5.3+ is partial.

Use it only in code that pins its own LuaJIT build.

## Hands-on exercises

??? example "Exercise 1: remove a trace abort"
    A loop creates a small closure per element. Count trace stops and aborts, then fix it.

    ??? success "Solution"
        ```lua
        --8<-- "examples/18-luajit/ex1_hoist_closure.lua"
        ```
        ```text
        --8<-- "examples/18-luajit/ex1_hoist_closure.expected"
        ```
        The slow version's loop is never compiled; the one stop is a trace for the tiny function body itself.

??? example "Exercise 2: a portable compatibility shim"
    Write `unpack`, `pack`, bit operations, floor division and an integer test that work on LuaJIT, 5.4 and 5.5. Hide 5.3+ operators from the LuaJIT parser.

    ??? success "Solution"
        ```lua
        --8<-- "examples/18-luajit/ex2_compat.lua"
        ```
        ```text
        --8<-- "examples/18-luajit/ex2_compat.expected"
        ```

??? example "Exercise 3: count the guards"
    Dump the IR of `for i = 1, #data do s = s + data[i] end` and list the guarded instructions.

    ??? success "Solution"
        ```lua
        --8<-- "examples/18-luajit/ex3_guards.lua"
        ```
        ```text
        --8<-- "examples/18-luajit/ex3_guards.expected"
        ```

??? example "Exercise 4: type stability"
    Sum an array of numbers and an array where every third element is a string. How many traces does each need?

    ??? success "Solution"
        ```lua
        --8<-- "examples/18-luajit/ex4_types.lua"
        ```
        ```text
        --8<-- "examples/18-luajit/ex4_types.expected"
        ```
        Here `jit.flush()` throws away all compiled traces, so the second run starts cold.

## Quiz

??? question "Q1. What triggers LuaJIT to record a trace?"
    A loop or function becoming hot: its counter reaching `hotloop` (56 by default). A
    frequently taken guard exit (`hotexit`, 10) triggers a side trace.

??? question "Q2. What does `NYI: bytecode FNEW` mean, and what is the fix?"
    Recording aborted because creating a closure is not compiled. Move the function
    creation out of the hot loop.

??? question "Q3. In `-jdump` IR, what does `>` mark?"
    A guard: a check that exits the trace if an assumption made during recording no longer holds.

??? question "Q4. Why should portable code not use `x += 1` even though LuaJIT 2.1 accepts it?"
    Only LuaJIT builds from July 2026 on accept it; PUC Lua, older LuaJIT builds and
    tooling all reject it as a syntax error.

??? question "Q5. Why does `9007199254740992 + 1` behave differently on LuaJIT and Lua 5.4?"
    LuaJIT numbers are doubles (53-bit mantissa); Lua 5.4 uses 64-bit integers for integer values.
