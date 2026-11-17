# 22. Lua from Rust with `mlua`

--8<-- "includes/badges/22-mlua.md"

!!! abstract "What you will be able to do after this lesson"
    - Embed Lua 5.5, 5.4 or LuaJIT in a Rust program with `mlua`, selected by a Cargo feature.
    - Move values, tables and functions between Rust and Lua with automatic conversions.
    - Expose Rust types to Lua with the `UserData` trait.
    - Convert errors in both directions and recover typed Rust errors.
    - Lend non-`'static` Rust data to Lua safely with `Lua::scope`.

## Which Lua versions does `mlua` support?

As of **mlua 0.12.2** (released 3 October 2026, the version this lesson pins and
tests), mlua supports **Lua 5.5, 5.4, 5.3, 5.2, 5.1, LuaJIT** (2.0/2.1, also in
5.2-compatibility mode) and **Luau**, one per build, chosen with a feature flag:
`lua55`, `lua54`, `lua53`, `lua52`, `lua51`, `luajit`, `luajit52`, `luau`. Lua 5.5
support arrived in 0.11.6 (January 2026); 0.12.1 updated the vendored copy to
Lua 5.5.1. The minimum supported Rust version is 1.88.

!!! note "For C++/Rust developers"
    `mlua` does what the C++ wrapper in Lesson 20 did by hand, with the type
    system's help: `Lua` owns the state, values are reference-counted handles
    tied to that state, conversions go through `IntoLua`/`FromLua`, every call into
    Lua is protected, and Rust panics and errors are carried across the Lua boundary
    without `longjmp` skipping your destructors.

## The crate and its features

```toml title="examples/22-mlua/Cargo.toml"
--8<-- "examples/22-mlua/Cargo.toml"
```

- Without `vendored`, `mlua-sys` finds Lua with `pkg-config`, or with the
  environment variables `LUA_LIB` (directory), `LUA_LIB_NAME` (`lua`,
  `luajit-5.1`, ...) and `LUA_LINK=static`. The test runner uses those to link
  each binary against the same `/opt` builds as the C examples:
  ```bash
  LUA_LIB=/opt/lua-5.5.1/lib LUA_LIB_NAME=lua LUA_LINK=static \
    cargo build --release --no-default-features --features lua55 --target-dir target/5.5
  LUA_LIB=/opt/luajit-2.1/lib LUA_LIB_NAME=luajit-5.1 LUA_LINK=static \
    cargo build --release --no-default-features --features luajit --target-dir target/jit
  ```
- With `vendored`, mlua builds Lua from source through the `lua-src` and
  `luajit-src` crates: the easiest way to start.
- Other useful features: `async` (Lua coroutines as Rust futures), `serde`
  (convert any `Serialize` type to and from Lua values), `send` (make `Lua: Send`),
  `macros`, and `module` for writing Lua C modules in Rust (`cdylib`).

The examples share one helper. Lua's `print` writes to C's `stdout` buffer
while `println!` uses Rust's, so their output can interleave out of order when
piped; the helper routes `print` through Rust:

```rust title="examples/22-mlua/src/lib.rs"
--8<-- "examples/22-mlua/src/lib.rs"
```

## Embedding

```rust title="examples/22-mlua/src/bin/embed.rs"
--8<-- "examples/22-mlua/src/bin/embed.rs"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/22-mlua/src/bin/embed.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/22-mlua/src/bin/embed.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/22-mlua/src/bin/embed.jit.expected"
    ```

Conversions are driven by the Rust types you ask for: `eval::<i64>`, tuples for
multiple values, `Option<T>` for "may be nil", `Vec<T>` for sequences,
`HashMap`/`Table` for tables, and closures with typed arguments for functions.

## Rust types as userdata

```rust title="examples/22-mlua/src/bin/userdata.rs"
--8<-- "examples/22-mlua/src/bin/userdata.rs"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/22-mlua/src/bin/userdata.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/22-mlua/src/bin/userdata.jit.expected"
    ```

- `add_field_method_get` exposes read-only fields; without a setter, assignment
  fails, as the second `pcall` shows.
- `add_method_mut` borrows the value mutably for the call; mlua tracks borrows at
  run time like `RefCell`, so re-entrant access raises an error instead of
  causing undefined behaviour.
- The object keeps living in Lua; Rust gets it back as `AnyUserData` and can
  `borrow_mut::<Frame>()` it.

## Errors in both directions

```rust title="examples/22-mlua/src/bin/errors.rs"
--8<-- "examples/22-mlua/src/bin/errors.rs"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/22-mlua/src/bin/errors.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/22-mlua/src/bin/errors.jit.expected"
    ```

- Lua failures come back as `mlua::Error` variants: `SyntaxError` (with an
  `incomplete_input` flag, useful for REPLs), `RuntimeError`,
  `FromLuaConversionError` for type mismatches, `MemoryError`, ...
- Any `std::error::Error + Send + Sync` becomes a Lua error with `.into_lua_err()`
  (`ExternalError`). Lua code sees an error value whose `tostring` is the message.
- When that error travels back into Rust it is wrapped in `CallbackError` (with a
  Lua traceback); `err.chain()` plus `downcast_ref` recovers the original typed error.

## Version differences through mlua

```rust title="examples/22-mlua/src/bin/versions.rs"
--8<-- "examples/22-mlua/src/bin/versions.rs"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/22-mlua/src/bin/versions.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/22-mlua/src/bin/versions.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/22-mlua/src/bin/versions.jit.expected"
    ```

- `_VERSION` and the error message wording follow the linked Lua. Code that
  matches on error *text* is version-specific; match on `mlua::Error` variants.
- LuaJIT has no integer subtype: mlua reports integral doubles as `Integer`, and
  `9007199254740993` silently becomes `...992`. Use `i64` values below 2^53, or
  strings, when LuaJIT is a target.
- mlua installs its own allocator, so `set_memory_limit` works on all three.
- `lua54`, `lua55` and `luajit` are mutually exclusive Cargo features; a crate that
  wants to support several builds them separately, like this lesson does. Code can
  branch on `cfg!(feature = "...")`.

## Hands-on exercises

??? example "Exercise 1: a typed configuration loader"
    Run a config script in its own environment table (so it cannot create globals), convert it into a Rust struct, and validate it.

    ??? success "Solution"
        ```rust
        --8<-- "examples/22-mlua/src/bin/ex1_config.rs"
        ```
        ```text
        --8<-- "examples/22-mlua/src/bin/ex1_config.expected"
        ```

??? example "Exercise 2: a userdata container"
    Expose a `Vec<i64>` as a Lua stack object with `push`, `pop`, `peek`, `#`, `tostring` and numeric indexing.

    ??? success "Solution"
        ```rust
        --8<-- "examples/22-mlua/src/bin/ex2_stack.rs"
        ```
        ```text
        --8<-- "examples/22-mlua/src/bin/ex2_stack.expected"
        ```

??? example "Exercise 3: borrowing Rust data with `scope`"
    Let Lua push strings into a local `Vec<String>` through a closure that borrows it mutably, then show that the function is invalid after the scope ends.

    ??? success "Solution"
        ```rust
        --8<-- "examples/22-mlua/src/bin/ex3_scope.rs"
        ```
        ```text
        --8<-- "examples/22-mlua/src/bin/ex3_scope.expected"
        ```

## Quiz

??? question "Q1. Which Lua versions can mlua 0.12.2 embed, and how do you choose?"
    Lua 5.5, 5.4, 5.3, 5.2, 5.1, LuaJIT and Luau, one per build, via the
    `lua55`/`lua54`/.../`luajit`/`luau` Cargo features.

??? question "Q2. How does a Rust error returned from a callback look to Lua code?"
    As an error value: `pcall` returns `false` and a value whose `tostring` is the
    Rust error's message.

??? question "Q3. How do you get the original Rust error type back after it crossed Lua?"
    Walk `err.chain()` and `downcast_ref::<YourError>()`; it is wrapped in `CallbackError`.

??? question "Q4. Why does `create_function` require `'static` closures, and what is the alternative?"
    Lua may keep the function forever, so it must not borrow short-lived data.
    `Lua::scope` creates functions that may borrow, and invalidates them when the scope ends.

??? question "Q5. What does the `vendored` feature do?"
    Builds and statically links Lua (or LuaJIT) from source via `lua-src`/`luajit-src`,
    so no system Lua installation is needed.
