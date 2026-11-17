# 13. Error Handling

--8<-- "includes/badges/13-errors.md"

!!! abstract "What you will be able to do after this lesson"
    - Choose between the two Lua error styles: `nil, message` returns and raised errors.
    - Raise errors with the right `level`, and raise structured error objects.
    - Catch errors with `pcall`, and capture tracebacks with `xpcall` and a message handler.
    - Guarantee cleanup with `<close>` (5.4+) or a portable `with` helper.

## Intuition: two channels for two kinds of failure

Lua has no `try`/`catch` syntax, but it has a clear convention:

| Failure kind | Example | Mechanism |
|---|---|---|
| **Expected**: the caller should handle it | file not found, invalid user input | return `nil, "message"` (sometimes plus an error code) |
| **Unexpected**: a bug or broken precondition | indexing `nil`, wrong argument type | `error(value)` unwinds the stack to the nearest `pcall` |

`assert(v, msg)` bridges the two: it passes `v` through if it is truthy and raises
`msg` otherwise, so `local f = assert(io.open(path))` turns a returned error into a
raised one.

!!! note "For C++/Rust developers"
    `nil, err` is Lua's `Result<T, E>` / `std::expected`, and `error` + `pcall` is
    exceptions / `panic` + `catch_unwind`. Unlike C++, any Lua value can be thrown,
    not just objects of an exception class, and nothing forces callers to look at
    the `nil, err` pair: the discipline is yours.

```lua title="examples/13-errors/two_styles.lua"
--8<-- "examples/13-errors/two_styles.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/13-errors/two_styles.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/13-errors/two_styles.jit.expected"
    ```

!!! info "Version difference: `assert` and positions"
    On Lua 5.4/5.5, a failing `assert` with a string message prefixes the
    position of the code that called `assert` (`two_styles.lua:21:`). LuaJIT raises
    the message unchanged. Runtime error wording also differs ("attempt to index a
    nil value (local 'cfg')" versus "attempt to index local 'cfg' (a nil value)").

## `error` and levels

`error(msg, level)` prefixes string messages with a position. `level` says whose
position: 1 (default) is the function that called `error`, 2 is *its* caller, and
0 adds nothing. Library functions use level 2 to blame the code that passed a bad
argument:

```lua title="examples/13-errors/levels.lua"
--8<-- "examples/13-errors/levels.lua"
```

```text
--8<-- "examples/13-errors/levels.expected"
```

!!! warning "Tail calls hide callers"
    If `caller` did `return check_positive(-1, level)`, that would be a tail call
    (Lesson 8): `caller`'s frame is gone, so level 2 would point at whoever called
    `caller`, here `pcall`, a C function, and the message would get no position.

## Error objects

Any value can be an error. Tables let you attach codes and context, and a
`__tostring` keeps them printable. Only **string** errors get a position prefix:

```lua title="examples/13-errors/error_objects.lua"
--8<-- "examples/13-errors/error_objects.lua"
```

```text
--8<-- "examples/13-errors/error_objects.expected"
```

LuaJIT treats a **number** error like a string (it gets a position and becomes a
string); Lua 5.4/5.5 pass it through unchanged:

```lua title="examples/13-errors/number_error.lua"
--8<-- "examples/13-errors/number_error.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/13-errors/number_error.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/13-errors/number_error.jit.expected"
    ```

## `xpcall` and tracebacks

`pcall` returns after the stack has unwound, so the traceback is lost. `xpcall(f,
handler, ...)` calls `handler(err)` **at the point of the error**, before
unwinding, so the handler can inspect the stack. `debug.traceback` is the usual
handler:

```lua title="examples/13-errors/traceback.lua"
--8<-- "examples/13-errors/traceback.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/13-errors/traceback.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/13-errors/traceback.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/13-errors/traceback.jit.expected"
    ```

Traceback formatting is not part of the language and differs in every version:
5.5 says `in global 'error'`, 5.4 says `in function 'error'`, LuaJIT does not
distinguish upvalues and ends with a C address. Never parse tracebacks.

A custom handler can return anything, for example a structured report:

```lua title="examples/13-errors/handler.lua"
--8<-- "examples/13-errors/handler.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/13-errors/handler.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/13-errors/handler.jit.expected"
    ```

## Cleaning up and re-raising

To release a resource and still propagate the original error, catch it, clean
up, and re-raise with level 0 so no second position is added:

```lua title="examples/13-errors/rethrow.lua"
--8<-- "examples/13-errors/rethrow.lua"
```

```text
--8<-- "examples/13-errors/rethrow.expected"
```

### `<close>`: cleanup without `pcall` (Lua 5.4+)

To-be-closed variables (Lesson 10) are closed while an error unwinds, in reverse
order, and their `__close` receives the error object:

```lua title="examples/13-errors/close_errors.lua"
--8<-- "examples/13-errors/close_errors.lua"
```

```text
--8<-- "examples/13-errors/close_errors.expected"
```

### A portable `with` helper

On LuaJIT, write the "finally" once:

```lua title="examples/13-errors/with_helper.lua"
--8<-- "examples/13-errors/with_helper.lua"
```

```text
--8<-- "examples/13-errors/with_helper.expected"
```

!!! info "Other version notes"
    - `error(nil)`: Lua 5.5 delivers the string `"<no error object>"` to `pcall`; 5.4 and LuaJIT deliver `nil` ([cheat sheet](../version-differences.md)).
    - `xpcall` with extra arguments works on 5.2+ and LuaJIT, not on plain 5.1.
    - Lua 5.4+ has `warn(msg)` for non-fatal warnings (to stderr, off by default; `warn("@on")` enables them). LuaJIT has no `warn`.

## Hands-on exercises

??? example "Exercise 1: parse or explain"
    Write `parse_resolution("1920x1080")` returning `w, h`, or `nil` plus a helpful
    message for every kind of bad input. It must never raise.

    ??? success "Solution"
        ```lua
        --8<-- "examples/13-errors/ex1_parse.lua"
        ```
        ```text
        --8<-- "examples/13-errors/ex1_parse.expected"
        ```

??? example "Exercise 2: retry"
    Write `retry(times, fn, ...)` that calls `fn` until it succeeds, printing each
    failure, and raises a summary error if it never does.

    ??? success "Solution"
        ```lua
        --8<-- "examples/13-errors/ex2_retry.lua"
        ```
        ```text
        --8<-- "examples/13-errors/ex2_retry.expected"
        ```

??? example "Exercise 3: error hierarchy"
    Create `IOError` and its subclass `NetworkError`, and dispatch on the error class
    after a `pcall`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/13-errors/ex3_hierarchy.lua"
        ```
        ```text
        --8<-- "examples/13-errors/ex3_hierarchy.expected"
        ```

??? example "Exercise 4: collect all validation errors"
    Validate a configuration table and return all problems at once, not just the first.

    ??? success "Solution"
        ```lua
        --8<-- "examples/13-errors/ex4_validate.lua"
        ```
        ```text
        --8<-- "examples/13-errors/ex4_validate.expected"
        ```

??? example "Exercise 5: try / catch / finally"
    Build a `try { fn, catch = ..., finally = ... }` helper on top of `xpcall` that
    passes the error and a traceback to `catch`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/13-errors/ex5_try.lua"
        ```
        ```text
        --8<-- "examples/13-errors/ex5_try.expected"
        ```

## Quiz

??? question "Q1. When should a function return `nil, err` instead of calling `error`?"
    When failure is an expected outcome the caller should handle (missing file,
    bad input). Raise errors for bugs and violated preconditions.

??? question "Q2. What does `error(\"bad\", 2)` do differently from `error(\"bad\")`?"
    It prefixes the position of the caller of the current function instead of the
    current function's own line.

??? question "Q3. Why can't you get a full traceback from the error returned by `pcall`?"
    By the time `pcall` returns, the stack has unwound. Use `xpcall` with a
    handler such as `debug.traceback`, which runs before unwinding.

??? question "Q4. Which errors get a `file:line:` prefix?"
    String errors raised with level 1 or higher (when that level is a Lua
    function). Tables are passed through untouched. Numbers are passed through on
    5.4/5.5 but converted and prefixed on LuaJIT.

??? question "Q5. How do you guarantee cleanup when an error occurs, on 5.4 and on LuaJIT?"
    On 5.4/5.5 use a `<close>` variable with a `__close` metamethod. On LuaJIT
    wrap the work in `pcall`, clean up, and re-raise with `error(err, 0)`.
