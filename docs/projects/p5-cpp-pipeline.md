# Project 5. A C++ Media Pipeline with a Sandboxed Lua Scripting Layer

--8<-- "includes/badges/p5-cpp-pipeline.md"

!!! abstract "What you will build"
    `mediapipe`, a C++17 program that pushes video frames (generated grayscale
    test frames, so no codec dependency) through a chain of **filters written in
    Lua**: `mediapipe scripts/brightness.lua:amount=-30 scripts/blur.lua`. Each
    script runs in its **own sandbox** with a **memory limit**, an
    **instruction limit** and a **wall-clock limit**, sees only a whitelisted
    environment, cannot load bytecode, cannot keep frames past their lifetime,
    and is unloaded (with its partial changes rolled back) when it misbehaves.
    It builds with **CMake** against **Lua 5.5, Lua 5.4 and LuaJIT 2.1**, and a
    set of deliberately hostile scripts proves every limit on all three.

    Uses: [C API I (20)](../part3/20-capi-embed.md) and [C API II (21)](../part3/21-capi-modules.md)
    (stack, userdata, metatables, `lua_pcall`, allocators, hooks),
    [error handling (13)](../part2/13-errors.md), [LuaJIT (18)](../part3/18-luajit.md). Source: `projects/p5-cpp-pipeline/`.

## Design first

The pipeline is a list of `Script` objects; each frame goes through them in
order. All Lua-specific code lives in `sandbox.cpp`.

| Threat (a script that...) | Defence | Where |
|---|---|---|
| reads files, runs programs, loads C code | a fresh **environment** with a whitelist: no `os`, `io`, `require`, `load`, `debug`, `package`, `getmetatable`, `collectgarbage` | `Script::load` |
| loads crafted **bytecode** (can crash the VM) | `luaL_loadbufferx(..., "t")`, and `string.dump` removed | `Script::load`, constructor |
| loops forever | a **count hook** every 1000 instructions that raises after the budget | `count_hook` |
| catches that error with `pcall` and keeps going | a host `pcall` that re-raises once the budget is spent | `host_pcall` |
| allocates without bound | a **custom allocator** with a per-state budget; Lua turns `NULL` into a memory error | `Script::alloc` |
| stalls (slow C calls) | a **deadline** checked in the hook, and once more after every call | `count_hook`, `Script::call` |
| keeps the frame userdata and uses it later | the userdata holds a pointer the host **clears** after `process()` | `FrameRef` |
| fails halfway through a frame | the host **restores** the frame from a copy | `Script::process` |
| interferes with another script | one `lua_State` per script: nothing is shared | `Script` constructor |

!!! note "For C++/Rust developers"
    `Script` is a non-copyable RAII owner of a `lua_State*` (`lua_close` in the
    destructor). The C API reports errors with `longjmp` (or C++ exceptions if
    Lua is *compiled as C++*), so never let one cross a frame that owns C++
    objects with destructors: all calls into scripts go through `lua_pcall`, and
    C functions called *by* Lua keep their intermediate data on the Lua stack
    (see `host_print`) rather than in `std::string`s that an error would skip.
    The `void *ud` of the allocator doubles as a back-pointer to the `Script`,
    the usual way to reach "self" from a C callback.

## Step 1: build setup

```cmake title="projects/p5-cpp-pipeline/CMakeLists.txt"
--8<-- "projects/p5-cpp-pipeline/CMakeLists.txt"
```

The tests build once per interpreter into `build/<id>/`:

```bash title="projects/p5-cpp-pipeline/build.sh"
--8<-- "projects/p5-cpp-pipeline/build.sh"
```

## Step 2: frames

```cpp title="projects/p5-cpp-pipeline/src/frame.hpp"
--8<-- "projects/p5-cpp-pipeline/src/frame.hpp"
```

??? info "frame.cpp (test pattern, FNV-1a checksum, stats, ASCII preview)"
    ```cpp
    --8<-- "projects/p5-cpp-pipeline/src/frame.cpp"
    ```

A checksum per stage makes the output comparable across interpreters: any
difference in arithmetic or rounding would change the FNV value.

## Step 3: the sandbox

```cpp title="projects/p5-cpp-pipeline/src/sandbox.hpp"
--8<-- "projects/p5-cpp-pipeline/src/sandbox.hpp"
```

```cpp title="projects/p5-cpp-pipeline/src/sandbox.cpp"
--8<-- "projects/p5-cpp-pipeline/src/sandbox.cpp"
```

Walk through it in this order:

1. **`protect`.** Every step the host performs on a state (opening the
   libraries, building an environment, wrapping a frame) allocates, and with a
   memory limit any allocation may fail. Outside a protected call, Lua then
   calls its *panic* function and **aborts the process**: an early version of
   this host died with `SIGABRT` when run with `--memory 16`. `protect` runs
   such a step through `lua_pcall` (`lua_cpcall` on 5.1/LuaJIT, where pushing
   a C function itself allocates).
2. **Constructor.** `lua_newstate(alloc, this)` installs the allocator (5.5
   takes a third argument, a hash seed). The full standard library is opened
   *in the state*, but scripts never see that global table: `load` gives the
   chunk its own environment. On LuaJIT the JIT is then switched **off** for
   the state, because LuaJIT does not run hooks inside compiled traces and a hot
   `while true do end` would never be interrupted. Order matters: opening the
   `jit` library switches the JIT back on, so calling `luaJIT_setmode` before
   `luaL_openlibs` has no effect. A draft did exactly that, and the `loop.lua`
   test hung on LuaJIT only.
3. **`load`.** Text-only loading, then the environment: whitelisted functions,
   *copies* of `string`, `table` and `math` (so a script that overwrites
   `string.rep` only breaks itself), our `pcall` and `print`, and `params`.
   Lua 5.2+ sets it as the chunk's first upvalue (`_ENV`); 5.1/LuaJIT use
   `lua_setfenv`. One `#if` covers both.
4. **`call`.** Arms the budget, the deadline and the hook, runs `lua_pcall`,
   disarms, and turns the outcome into one error line.
5. **`process`.** Wraps the frame in a `FrameRef` userdata, calls the script's
   `process`, then clears the pointer: a stored reference now raises
   "frame used after process() returned" instead of reading freed memory.

`frame:get` uses `lua_pushinteger`, so values print as `255` and not `255.0`
on 5.4/5.5. Coordinates are read with `luaL_checknumber` and truncated, because
`luaL_checkinteger` rejects `1.5` on 5.4+ but truncates it on LuaJIT.

## Step 4: the driver

```cpp title="projects/p5-cpp-pipeline/src/main.cpp"
--8<-- "projects/p5-cpp-pipeline/src/main.cpp"
```

## Step 5: filters

```lua title="projects/p5-cpp-pipeline/scripts/invert.lua"
--8<-- "projects/p5-cpp-pipeline/scripts/invert.lua"
```

```lua title="projects/p5-cpp-pipeline/scripts/brightness.lua"
--8<-- "projects/p5-cpp-pipeline/scripts/brightness.lua"
```

??? info "histogram.lua, blur.lua, edges.lua"
    ```lua title="scripts/histogram.lua"
    --8<-- "projects/p5-cpp-pipeline/scripts/histogram.lua"
    ```
    ```lua title="scripts/blur.lua"
    --8<-- "projects/p5-cpp-pipeline/scripts/blur.lua"
    ```
    ```lua title="scripts/edges.lua"
    --8<-- "projects/p5-cpp-pipeline/scripts/edges.lua"
    ```

Scripts keep state in locals between frames (the histogram could average over
time, for instance), but they only ever touch pixels through `frame:get/set`.

```bash title="projects/p5-cpp-pipeline/pipeline.test.sh"
--8<-- "projects/p5-cpp-pipeline/pipeline.test.sh"
```

```text title="Output (identical with Lua 5.5, 5.4 and LuaJIT)"
--8<-- "projects/p5-cpp-pipeline/pipeline.expected"
```

## Step 6: attacking the sandbox

```lua title="projects/p5-cpp-pipeline/hostile/escape.lua"
--8<-- "projects/p5-cpp-pipeline/hostile/escape.lua"
```

??? info "The other hostile scripts"
    ```lua title="hostile/loop.lua"
    --8<-- "projects/p5-cpp-pipeline/hostile/loop.lua"
    ```
    ```lua title="hostile/pcall_loop.lua"
    --8<-- "projects/p5-cpp-pipeline/hostile/pcall_loop.lua"
    ```
    ```lua title="hostile/memory.lua"
    --8<-- "projects/p5-cpp-pipeline/hostile/memory.lua"
    ```
    ```lua title="hostile/half_done.lua"
    --8<-- "projects/p5-cpp-pipeline/hostile/half_done.lua"
    ```
    ```lua title="hostile/keep_frame.lua"
    --8<-- "projects/p5-cpp-pipeline/hostile/keep_frame.lua"
    ```
    ```lua title="hostile/no_process.lua"
    --8<-- "projects/p5-cpp-pipeline/hostile/no_process.lua"
    ```

```bash title="projects/p5-cpp-pipeline/sandbox.test.sh"
--8<-- "projects/p5-cpp-pipeline/sandbox.test.sh"
```

```text title="Output (identical with Lua 5.5, 5.4 and LuaJIT)"
--8<-- "projects/p5-cpp-pipeline/sandbox.expected"
```

The last command shows a limit too small even for the standard library: the
script fails cleanly instead of the host aborting. Note that `half_done.lua`'s failure leaves the frame exactly as `escape.lua`
produced it (same FNV), and `invert.lua` at the end runs on every frame.

The `backtrack.lua` run is Exercise 4's attack: see below for why the time
limit can only *detect* it.

## Step 7: what differs between interpreters

```bash title="projects/p5-cpp-pipeline/version.test.sh"
--8<-- "projects/p5-cpp-pipeline/version.test.sh"
```

=== "Lua 5.5"
    ```text
    --8<-- "projects/p5-cpp-pipeline/version.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "projects/p5-cpp-pipeline/version.5.4.expected"
    ```
=== "LuaJIT"
    ```text
    --8<-- "projects/p5-cpp-pipeline/version.jit.expected"
    ```

!!! info "Version notes"
    - **Builds against all three** from the same source: `lua.hpp` exists in
      every distribution; `LUA_OK` is defined for 5.1; `lua_newstate` gained a
      seed parameter in 5.5; environments are `_ENV` upvalues (5.2+) or `setfenv`
      (5.1/LuaJIT).
    - **LuaJIT hooks** only run in the interpreter, so the JIT is off in every
      sandboxed state: scripts run at interpreter speed.
    - **LuaJIT and custom allocators**: LuaJIT 2.1 accepts the allocator passed
      to `lua_newstate` only in GC64 builds (the default on x86-64 today, and the
      build tested here). Older non-GC64 64-bit builds return `NULL` there, which
      the constructor reports as "could not create a Lua state".
    - The bytecode error message differs (`attempt to load chunk with wrong mode`
      on LuaJIT); hosts should not match on it.
    - Integer subtype: 5.4/5.5 distinguish `255` from `255.0`; pushing with
      `lua_pushinteger` keeps output identical with LuaJIT, which has only doubles.

!!! warning "What this sandbox does not do"
    - **It cannot interrupt a long C call.** Hooks run between Lua instructions.
      `hostile/backtrack.lua` spends about 0.6 s inside one `string.find` while
      the limit is 0.1 s; the host notices only *after* the call returns. With
      a longer subject string the same pattern ran for over a minute here. For
      untrusted code that must be stopped on time, run scripts in a separate
      process (killed by a watchdog, or limited with `setrlimit(RLIMIT_CPU)`),
      or replace the pattern functions with bounded versions.
    - Memory accounting covers the Lua heap only; it is per state, not global.
    - It has been reviewed and attacked with the scripts above, not audited.
      Treat it as a starting point, not a security boundary for hostile users.

## Extension exercises

??? example "Exercise 1: unsharp masking"
    Write `sharpen.lua`: `v + amount * (v - blurred)`, with `amount` from
    `params`. Read all pixels first, so you don't blur already-sharpened ones.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p5-cpp-pipeline/scripts/ex1_sharpen.lua"
        ```

??? example "Exercise 2: motion detection"
    Report how many pixels changed by more than a threshold since the previous
    frame. Where must the previous frame live?

    ??? success "Solution"
        In a Lua table of plain numbers: the frame userdata expires after
        `process` returns.

        ```lua
        --8<-- "projects/p5-cpp-pipeline/scripts/ex2_motion.lua"
        ```

??? example "Exercise 3: mirror"
    Flip each row left-right in place.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p5-cpp-pipeline/scripts/ex3_mirror.lua"
        ```

    The three solutions run in one pipeline:

    ```bash title="exercises.test.sh"
    --8<-- "projects/p5-cpp-pipeline/exercises.test.sh"
    ```

    ```text
    --8<-- "projects/p5-cpp-pipeline/exercises.expected"
    ```

??? example "Exercise 4: beat the time limit"
    Write a script that runs far longer than `--seconds` while executing very
    few Lua instructions. Then explain what the host can and cannot do about it.

    ??? success "Solution"
        Spend the time inside one C function. A pattern with several `.-`
        that can never match makes `string.find` backtrack through millions of
        splits:

        ```lua
        --8<-- "projects/p5-cpp-pipeline/hostile/backtrack.lua"
        ```

        The count hook never fires during the call, and afterwards fewer than
        1000 instructions remain, so the hook does not fire at all. The host
        therefore checks the deadline once more after `lua_pcall` returns
        (the output of Step 6 shows the result):

        ```cpp
        --8<-- "projects/p5-cpp-pipeline/src/sandbox.cpp:limits"
        ```

        That is *detection*, not prevention. To actually stop it, isolate the
        script in a child process and kill it on timeout, or remove/wrap
        `string.find`, `match`, `gmatch` and `gsub` (e.g. limit subject length
        and the number of `.-`/`*` items in a pattern).

## Quiz

??? question "Q1. Why does the sandbox replace `pcall`?"
    The limit is raised as a Lua error, which a plain `pcall` would catch, letting
    the script continue forever. The host `pcall` re-raises once the budget is spent.

??? question "Q2. Why is the JIT switched off on LuaJIT?"
    LuaJIT runs hooks only in its interpreter, not inside compiled traces, so a
    compiled loop would never see the instruction-count hook.

??? question "Q3. How does the host stop a script from using a frame after `process` returns?"
    The userdata holds a pointer that the host sets to `NULL` after the call;
    every frame method checks it and raises an error.

??? question "Q4. Why load with mode `\"t\"`?"
    Lua does not verify bytecode; crafted bytecode can corrupt memory. Text-only
    loading (and removing `string.dump`) keeps bytecode out.

??? question "Q5. What happens when the allocator returns `NULL`?"
    Lua raises a memory error. Inside a protected call that becomes `LUA_ERRMEM`,
    and the host reports "memory limit exceeded" and unloads the script; outside
    one, Lua panics and aborts the program, which is why even the host's own
    setup steps run through `protect`.
