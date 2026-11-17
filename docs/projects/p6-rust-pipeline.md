# Project 6 (Bonus). The Same Scripting Layer in Rust with mlua

--8<-- "includes/badges/p6-rust-pipeline.md"

!!! abstract "What you will build"
    The Project 5 host, rewritten in Rust with [mlua](https://github.com/mlua-rs/mlua)
    0.12.2: the **same command line, the same Lua filter scripts, the same
    limits**, and byte-identical output for every well-behaved pipeline. It
    builds against Lua 5.5, 5.4 and LuaJIT through Cargo features, linked
    statically against the course's own Lua builds. Comparing the two hosts
    line by line shows what a safe binding gives you for free, and where it
    behaves differently.

    Prerequisites: [Project 5](p5-cpp-pipeline.md) and [Rust with mlua (22)](../part3/22-mlua.md).
    Source: `projects/p6-rust-pipeline/`.

## Design first

The architecture is Project 5's; what changes is *who enforces what*:

| Concern | C++ host (P5) | Rust host (P6) |
|---|---|---|
| state lifetime | RAII class, `lua_close` in the destructor | `Lua` owns the state, `Drop` closes it |
| which libraries exist | open all, expose a whitelist | `Lua::new_with(StdLib::STRING \| TABLE \| MATH)`: `io`, `os`, `package`, `debug` are never opened; plus the same whitelist |
| memory limit | hand-written allocator | `lua.set_memory_limit(bytes)` |
| allocation failure outside scripts | must wrap host steps in `lua_pcall` (or Lua aborts) | every mlua call is already protected; you get `Err(MemoryError)` |
| instruction / time limit | `lua_sethook` with a C callback | `lua.set_hook(HookTriggers::new().every_nth_instruction(1000), closure)` |
| frame lifetime | userdata with a pointer the host clears | `lua.scope` + `create_userdata_ref_mut`: the borrow checker proves the handle cannot outlive the call |
| bytecode | `luaL_loadbufferx(..., "t")` | `.set_mode(ChunkMode::Text)` |
| errors | `lua_pcall` status codes and strings | `mlua::Error` enum (`RuntimeError`, `MemoryError`, `CallbackError`, ...) |

!!! note "For C++/Rust developers"
    mlua's central trick is `Lua::scope`: values created in a scope may borrow
    non-`'static` Rust data (here `&mut Frame`), and when the scope ends mlua
    **destructs** the Lua-side handles. Any later use raises "userdata has been
    destructed". That is exactly the hand-written `FrameRef` expiry of
    Project 5, but checked by the compiler on the Rust side. Shared mutable
    state between the hook and the host is an `Rc<Budget>` of `Cell`s: the hook
    closure must be `'static`, and everything is single-threaded.

## Step 1: Cargo features for three Lua versions

```toml title="projects/p6-rust-pipeline/Cargo.toml"
--8<-- "projects/p6-rust-pipeline/Cargo.toml"
```

mlua's build script links whichever Lua `LUA_LIB`/`LUA_LIB_NAME`/`LUA_LINK`
point at; the feature tells it which API to expect. Each build goes to its own
target directory so switching features does not rebuild everything:

```bash title="projects/p6-rust-pipeline/build.sh"
--8<-- "projects/p6-rust-pipeline/build.sh"
```

Without those variables, add `--features vendored` and mlua compiles its own
copy of the chosen Lua (no system Lua needed).

## Step 2: the frame

```rust title="projects/p6-rust-pipeline/src/frame.rs"
--8<-- "projects/p6-rust-pipeline/src/frame.rs"
```

The FNV-1a checksum and the ASCII preview are ported byte for byte, so the
outputs can be compared with `diff`.

## Step 3: the sandbox

```rust title="projects/p6-rust-pipeline/src/sandbox.rs"
--8<-- "projects/p6-rust-pipeline/src/sandbox.rs"
```

Things to notice:

- `impl UserData for Frame` replaces the hand-written metatable, `__index`
  and `luaL_checkudata` code. `get` returns `i64`, which mlua pushes as a Lua
  integer on 5.4/5.5 (and a number on LuaJIT), matching the C++ host's output.
- On LuaJIT the `jit` library is opened only so that `jit.off()` can be called;
  it is not in the scripts' environment.
- The hook returns `Err(...)` to abort the script. The host `pcall` checks the
  shared budget and re-raises, as in C++.
- `finish` performs the same after-the-call deadline check as Project 5, for
  time burnt inside one C function (Exercise 4 of Project 5).

## Step 4: the command line

```rust title="projects/p6-rust-pipeline/src/main.rs"
--8<-- "projects/p6-rust-pipeline/src/main.rs"
```

## Step 5: same scripts, same output

The test runs Project 5's scripts through the Rust binary and `diff`s against
Project 5's expected output:

```bash title="projects/p6-rust-pipeline/pipeline.test.sh"
--8<-- "projects/p6-rust-pipeline/pipeline.test.sh"
```

```text title="Output (Lua 5.5, 5.4 and LuaJIT)"
--8<-- "projects/p6-rust-pipeline/pipeline.expected"
```

## Step 6: the hostile scripts, and the differences

```bash title="projects/p6-rust-pipeline/sandbox.test.sh"
--8<-- "projects/p6-rust-pipeline/sandbox.test.sh"
```

```text title="Output (Lua 5.5, 5.4 and LuaJIT)"
--8<-- "projects/p6-rust-pipeline/sandbox.expected"
```

Every hostile script is stopped by the same limit with the same message,
except two, both honest differences rather than bugs:

1. **Expired frame.** In the C++ host the expired handle still exists and
   prints as `Frame(expired)`; only *using* it fails. mlua destructs scoped
   userdata completely, so even `tostring(previous)` raises
   "userdata has been destructed", and the script's first `print` never happens.
2. **Too little memory for the standard library.** Both hosts fail cleanly;
   mlua reports its own `MemoryError` wording.

## Step 7: versions

```bash title="projects/p6-rust-pipeline/version.test.sh"
--8<-- "projects/p6-rust-pipeline/version.test.sh"
```

=== "Lua 5.5"
    ```text
    --8<-- "projects/p6-rust-pipeline/version.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "projects/p6-rust-pipeline/version.5.4.expected"
    ```
=== "LuaJIT"
    ```text
    --8<-- "projects/p6-rust-pipeline/version.jit.expected"
    ```

!!! info "Version notes"
    - mlua is pinned to **0.12.2** (`=0.12.2` plus `Cargo.lock`); its API changed
      noticeably between 0.9, 0.10 and 0.11 (`ChunkMode` now lives in
      `mlua::chunk`, `Lua::scope` signatures changed), so expect small edits for
      other versions. The Lua 5.5 feature requires a recent mlua.
    - With LuaJIT, mlua refuses bytecode with the same message as PUC Lua
      ("attempt to load a binary chunk (mode is 't')") while the C++ host on raw
      LuaJIT gets "attempt to load chunk with wrong mode": mlua-sys's Lua 5.1
      compatibility layer checks the mode itself, with PUC Lua's wording,
      before LuaJIT sees the chunk.
    - Rust 2024 edition; tested with rustc 1.100.0 (stable).
    - `params` values are parsed with Rust's `f64::from_str`, the C++ host uses
      Lua's own number conversion: they agree for the decimal values used here,
      but not for hex strings like `0x10`.

## Extension exercises

??? example "Exercise 1: a typed parameter API"
    Instead of the raw `params` table, give scripts `param(name, default)` that
    returns the default when the parameter is missing, a number when the default
    is a number (and raises an error for a non-numeric value), and a string otherwise.

    ??? success "Solution"
        In `make_env` (it is part of the tested build):

        ```rust
        --8<-- "projects/p6-rust-pipeline/src/sandbox.rs:param"
        ```

        ```lua title="scripts/ex1_param.lua"
        --8<-- "projects/p6-rust-pipeline/scripts/ex1_param.lua"
        ```

        ```bash title="exercises.test.sh"
        --8<-- "projects/p6-rust-pipeline/exercises.test.sh"
        ```

        ```text title="Output (Lua 5.5, 5.4 and LuaJIT)"
        --8<-- "projects/p6-rust-pipeline/exercises.expected"
        ```

        The error is raised while the script loads, so the script is
        unloaded before the first frame, like any other load failure.

??? example "Exercise 2: run filters on worker threads"
    Why can't you move a `Script` to another thread as written, and what
    would you change?

    ??? success "Solution"
        `Lua` is `!Send` by default and the budget is an `Rc<Cell<...>>`. Enable
        mlua's `send` feature (which makes `Lua: Send` and requires `Send`
        callbacks), switch `Rc<Budget>` to `Arc` with atomics, and give each
        thread its own `Script`s: a Lua state must never be used from two
        threads at once, so parallelism is *per frame* or *per pipeline*,
        not inside one script.

??? example "Exercise 3: compare the two hosts' performance"
    Time `--frames 50 scripts/blur.lua` with both hosts on each interpreter.
    What do you expect, and why is LuaJIT not much faster here?

    ??? success "Solution"
        Both hosts spend almost all their time inside the same Lua VM, so they
        should be close; mlua adds a little per call for its safety checks. LuaJIT
        runs with the **JIT off** (needed for the instruction hook), so its
        interpreter speed is what you measure. Timings are machine-dependent, so
        this course does not record them as expected output.

## Quiz

??? question "Q1. What does `Lua::scope` guarantee?"
    Userdata created in the scope may borrow non-`'static` data, and they are
    destructed when the scope ends, so Lua can never use them afterwards.

??? question "Q2. Why does the Rust host not need Project 5's `protect` helper?"
    mlua performs its own C API calls in protected mode and turns failures,
    including out-of-memory, into `mlua::Error` values.

??? question "Q3. How do you select the Lua version in mlua?"
    With exactly one Cargo feature (`lua55`, `lua54`, `luajit`, ...), optionally
    with `vendored` to build Lua from source.

??? question "Q4. Why does the budget use `Rc<Cell<...>>`?"
    The hook closure and the host `pcall` closure both need to read and update
    it, closures given to mlua must be `'static`, and everything runs on one thread.

??? question "Q5. Which outputs differ between the C++ and the Rust host?"
    The expired-frame case (destructed userdata vs. a cleared pointer) and the
    wording of the out-of-memory-at-setup error; all pipelines are byte-identical.
