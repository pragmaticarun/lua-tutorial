# 17. Performance: Measure, Then Optimise

--8<-- "includes/badges/17-performance.md"

!!! abstract "What you will be able to do after this lesson"
    - Benchmark Lua code honestly, with a harness that also checks correctness.
    - Know which idioms matter on PUC Lua (5.4/5.5) and which matter on LuaJIT.
    - Read real numbers for locals, string building, table appends, iteration,
      allocation and closures on all three interpreters.

## Intuition: the interpreter tax is per operation

PUC Lua is a register-based bytecode interpreter. Roughly, cost is proportional to
the number of VM instructions and C calls you execute, plus allocation (which
later becomes GC work). So the classic advice is: fewer table lookups, fewer
calls, fewer temporary tables and strings. LuaJIT changes the picture: a trace
compiler turns hot loops into machine code, removes lookups and even allocations,
so "micro-optimisations" often vanish, while a few patterns (anything that stops
a trace from compiling) matter much more.

!!! note "For C++/Rust developers"
    Think `-O0` debug build for PUC Lua: nothing is hoisted, inlined or kept in a
    register for you, so manual hoisting pays. LuaJIT is closer to an optimising
    compiler, with its own "what defeats the optimiser" rules. In both, measure
    before believing, exactly as you would with `perf` and Criterion.

## A benchmark harness that is also a test

Timing output is never the same twice, so it cannot be an `.expected` file. Each
benchmark in this lesson therefore has two modes, via the `bench` module below:

- normal run (what `tests/run_all.sh` checks): run each variant once and check that
  all variants return the same checksum. Deterministic output, and it proves the
  "fast" version still computes the right answer.
- `LUA_BENCH=1`: time each variant with `os.clock` (CPU time), best of 5 runs
  after a full GC. `tests/bench.sh` runs this on every interpreter and generates
  the results table at the end of the lesson.

```lua title="examples/17-performance/bench.lua"
--8<-- "examples/17-performance/bench.lua"
```

```bash
cd examples/17-performance
lua5.5 strings.lua                 # correctness check
LUA_BENCH=1 lua5.5 strings.lua     # timings
tests/bench.sh                     # from the repo root: all benchmarks, all interpreters
```

## 1. Locals, upvalues and globals

```lua title="examples/17-performance/locals.lua"
--8<-- "examples/17-performance/locals.lua"
```

```text
--8<-- "examples/17-performance/locals.expected"
```

`math.floor` is two hash lookups (`_ENV.math`, then `.floor`) per iteration; a
local is a register. An upvalue costs one indirection, which measures the same
as a local here. On LuaJIT all three are identical: the trace compiler hoists the
lookups for you.

## 2. Building strings

```lua title="examples/17-performance/strings.lua"
--8<-- "examples/17-performance/strings.lua"
```

```text
--8<-- "examples/17-performance/strings.expected"
```

Strings are immutable, so `s = s .. x` copies the whole string every time:
quadratic. This is the one optimisation that matters everywhere, LuaJIT included
(the JIT cannot fix an O(n²) algorithm, and it was the *slowest* of all three on
this benchmark).

## 3. Appending to arrays

```lua title="examples/17-performance/tables.lua"
--8<-- "examples/17-performance/tables.lua"
```

```text
--8<-- "examples/17-performance/tables.expected"
```

`table.insert` is a C call plus a length computation; `t[#t + 1]` still computes
the length (a binary search) every time. A running counter is cheapest. Lua 5.5
adds `table.create(narray, nhash)`, which preallocates and avoids the repeated
resizes while the array grows. LuaJIT has the same idea as `require("table.new")(narray, nhash)`, and C code has always had `lua_createtable`.

## 4. Iterating arrays

```lua title="examples/17-performance/iteration.lua"
--8<-- "examples/17-performance/iteration.lua"
```

```text
--8<-- "examples/17-performance/iteration.expected"
```

On PUC Lua a numeric `for` avoids the iterator function call per element. On
LuaJIT `ipairs` compiles to the same loop as numeric `for`, while `pairs` is
noticeably slower.

## 5. Temporary tables

```lua title="examples/17-performance/allocation.lua"
--8<-- "examples/17-performance/allocation.lua"
```

```text
--8<-- "examples/17-performance/allocation.expected"
```

Each `{ x = ..., y = ... }` is an allocation plus later GC work. Returning
multiple values avoids both. LuaJIT's *allocation sinking* removes the temporary
tables entirely here, so both variants run at the same speed.

## 6. Closures in loops

```lua title="examples/17-performance/closures.lua"
--8<-- "examples/17-performance/closures.lua"
```

```text
--8<-- "examples/17-performance/closures.expected"
```

Creating a closure allocates. Hoist callbacks out of hot loops; on LuaJIT the
difference is larger because closure creation (`FNEW`) is not compiled. `-jv`
shows the trace aborting:

```text
$ luajit -jv closures.lua
[TRACE --- closures.lua:16 -- NYI: bytecode FNEW   at closures.lua:17]
```

## Measured results

--8<-- "includes/bench/17-performance.md"

What the numbers say:

- **Algorithms beat micro-optimisations**: memoizing Fibonacci or replacing
  `s = s .. x` gives 5× to 1000× on every interpreter; hoisting lookups into locals gives about 1.3–2.5×.
- **Lua 5.5 vs 5.4**: very close on these loops; 5.5 is ahead on allocation-heavy
  code (vector maths, byte scanning), 5.4 slightly ahead on some array appends.
  `table.create` (5.5 only) halves the append time again.
- **LuaJIT**: 10–100× faster on numeric loops, but no faster on quadratic string
  building. Even with the JIT off (`-joff`), its interpreter beats PUC Lua on most
  rows, but not on quadratic string building or `table.insert`/`#t` appends.
- PUC Lua idioms (hoisting `math.floor`, avoiding `ipairs`) make no difference on LuaJIT.

## Profiling before optimising

- **LuaJIT**: `luajit -jp=vl script.lua` is a built-in sampling profiler (per
  function and line); `-jv` shows which traces compiled and why others aborted.
- **PUC Lua**: `perf record`/`perf report` on the `lua` binary shows VM hot spots
  (`luaV_execute`, `luaH_get*`, GC). For Lua-level hot spots use a count hook
  (`debug.sethook(f, "", 1000)`) that samples `debug.getinfo(2, "Sl")`, as in
  Lesson 15, or a library such as LuaProfiler.
- Always benchmark with the GC in a known state (the harness does a full collect
  first), with realistic data sizes, and on the interpreter you ship.

!!! tip "Rules of thumb"
    1. Get the algorithm and data layout right first (Exercise 3).
    2. Never build strings with `..` in a loop; use a buffer and `table.concat`.
    3. In PUC Lua hot loops: hoist table and global lookups into locals, use a
       running index, avoid temporary tables and closures.
    4. On LuaJIT: keep hot paths free of non-compiled operations, and check with `-jv`.

## Hands-on exercises

Each solution is checked like a benchmark: the slow and fast variants must return
the same checksum, and the timings appear in the measured results table above.

??? example "Exercise 1: speed up a gain loop"
    Speed up a per-sample gain and clipping loop that reads `cfg` fields and calls globals on every sample.

    ??? success "Solution"
        ```lua
        --8<-- "examples/17-performance/ex1_hoist.lua"
        ```
        ```text
        --8<-- "examples/17-performance/ex1_hoist.expected"
        ```

??? example "Exercise 2: CSV without quadratic copying"
    Generate a 5000-line CSV report two ways and compare.

    ??? success "Solution"
        ```lua
        --8<-- "examples/17-performance/ex2_csv.lua"
        ```
        ```text
        --8<-- "examples/17-performance/ex2_csv.expected"
        ```

??? example "Exercise 3: algorithm first"
    Compare naive recursive Fibonacci with a memoized version.

    ??? success "Solution"
        ```lua
        --8<-- "examples/17-performance/ex3_memo.lua"
        ```
        ```text
        --8<-- "examples/17-performance/ex3_memo.expected"
        ```

??? example "Exercise 4: scanning bytes"
    Sum the bytes of a 1 MiB string as fast as possible.

    ??? success "Solution"
        ```lua
        --8<-- "examples/17-performance/ex4_bytes.lua"
        ```
        ```text
        --8<-- "examples/17-performance/ex4_bytes.expected"
        ```
        `string.byte(s, i, j)` returns several bytes per call, cutting the number of C calls by 8.

## Quiz

??? question "Q1. Why can't benchmark timings be checked by the test runner?"
    They change on every run. The runner checks deterministic checksums instead;
    `tests/bench.sh` records timings separately.

??? question "Q2. Which optimisation helped on all three interpreters in the measurements?"
    Replacing `s = s .. x` in a loop with a buffer and `table.concat`
    (and memoization, which is algorithmic).

??? question "Q3. Why is `local floor = math.floor` faster on PUC Lua but not on LuaJIT?"
    PUC Lua performs two table lookups per call to `math.floor`; LuaJIT's trace
    compiler hoists those lookups out of the loop automatically.

??? question "Q4. What does `table.create` do and where is it available?"
    It creates a table with preallocated array and hash parts; it is new in Lua 5.5.

??? question "Q5. How do you find out why a LuaJIT loop is slow?"
    Run with `-jv` to see trace aborts (NYI operations), and profile with `-jp`.
