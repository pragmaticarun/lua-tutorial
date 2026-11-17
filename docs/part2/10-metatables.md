# 10. Metatables and Metamethods

--8<-- "includes/badges/10-metatables.md"

!!! abstract "What you will be able to do after this lesson"
    - Attach a metatable to a table and customise lookups with `__index` and `__newindex`.
    - Give your own types operators (`__add`, `__eq`, `__lt`, `__concat`, `__tostring`, `__call`).
    - Release resources deterministically with `<close>` variables and `__close`.
    - Know which metamethod rules changed between Lua 5.1/LuaJIT, 5.4 and 5.5.

## Intuition: a table of "what to do when…"

Every table (and every userdata) can have a **metatable**: an ordinary table whose
specially named fields tell Lua what to do when an operation would otherwise fail
or use the default behaviour.

- `t.k` finds nothing? Lua looks at `getmetatable(t).__index`.
- `a + b` on tables? Lua looks for `__add` in either operand's metatable.
- `t(...)` on a table? Lua looks for `__call`.

That is the whole mechanism. Objects, inheritance, proxies, read-only tables,
operator overloading and RAII-style cleanup are all built from it.

!!! note "For C++/Rust developers"
    A metatable is a **vtable you attach at run time**: `__add` is `operator+` /
    `impl Add`, `__eq` is `operator==` / `PartialEq`, `__tostring` is `Display`,
    `__call` is `operator()` / `Fn`, `__close` is a destructor / `Drop` for a
    scoped variable, and `__index` is a fallback lookup, the core of Lua's
    prototype inheritance (Lesson 11). Unlike C++, nothing is resolved at compile
    time, and a metatable can be shared by thousands of values.

## `__index`: fallback lookups

When `__index` is a **table**, missing keys are looked up there:

```lua title="examples/10-metatables/defaults.lua"
--8<-- "examples/10-metatables/defaults.lua"
```

```text
--8<-- "examples/10-metatables/defaults.expected"
```

When `__index` is a **function**, it is called as `__index(t, k)` and its result is
the value. Use `rawget` / `rawset` to bypass metamethods:

```lua title="examples/10-metatables/index_fn.lua"
--8<-- "examples/10-metatables/index_fn.lua"
```

```text
--8<-- "examples/10-metatables/index_fn.expected"
```

## `__newindex`: intercepting writes

`__newindex` is called when you assign to a key that is **absent** from the
table. Combined with an empty proxy table (so that *every* access is a miss),
it lets you validate all reads and writes:

```lua title="examples/10-metatables/strict.lua"
--8<-- "examples/10-metatables/strict.lua"
```

```text
--8<-- "examples/10-metatables/strict.expected"
```

`error(msg, 2)` blames the caller's line instead of the metamethod: that is why
the messages point at lines 19 and 20.

## Operators

```lua title="examples/10-metatables/vector.lua"
--8<-- "examples/10-metatables/vector.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/10-metatables/vector.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/10-metatables/vector.jit.expected"
    ```

| Metamethod | Operation | Notes |
|---|---|---|
| `__add __sub __mul __div __mod __pow __unm` | `+ - * / % ^ -x` | Lua tries the left operand's metatable first, then the right one. |
| `__idiv __band __bor __bxor __shl __shr __bnot` | `// & \| ~ << >> ~x` | Lua 5.3+ only. LuaJIT: none (its new bit operators have no metamethods). |
| `__concat` | `..` | Called when either operand is not a string or number. |
| `__len` | `#` | For tables: 5.2+ only. LuaJIT ignores it for tables. |
| `__eq` | `==` `~=` | Only for two tables (or two userdata), and never for identical values. |
| `__lt` `__le` | `< <= > >=` | `a > b` is evaluated as `b < a`. |
| `__call` | `t(...)` | |
| `__tostring` | `tostring`, `print` | |
| `__name` | error messages, `tostring` | Used by PUC-Rio Lua 5.3+. |
| `__close` | end of a `<close>` variable's scope | Lua 5.4+. |
| `__index` `__newindex` | missing key read / write | Table or function. |
| `__metatable` | `getmetatable` / `setmetatable` | Protects the metatable. |
| `__gc` `__mode` | finalizer, weak table | [Lesson 16](16-gc.md). |

### Comparison rules differ between versions

Lua 5.3 and earlier evaluated `a <= b` as `not (b < a)` when there was no `__le`.
Lua 5.4 removed that rule but kept it behind the `LUA_COMPAT_LT_LE` option, which
the **default 5.4 build enables**. Lua 5.5 dropped it for good:

```lua title="examples/10-metatables/le_fallback.lua"
--8<-- "examples/10-metatables/le_fallback.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/10-metatables/le_fallback.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/10-metatables/le_fallback.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/10-metatables/le_fallback.jit.expected"
    ```

!!! warning "Porting trap: always define `__le` explicitly"
    Code that only defines `__lt` and uses `<=` works on 5.4 and LuaJIT but raises
    `attempt to compare two table values` on 5.5.

`__eq` changed too. Lua 5.1/LuaJIT only call `__eq` when both operands share the
**same** metamethod; Lua 5.3+ use the first operand's `__eq`, or the second's:

```lua title="examples/10-metatables/eq_rules.lua"
--8<-- "examples/10-metatables/eq_rules.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/10-metatables/eq_rules.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/10-metatables/eq_rules.jit.expected"
    ```

## `__call`: callable objects

```lua title="examples/10-metatables/call.lua"
--8<-- "examples/10-metatables/call.lua"
```

```text
--8<-- "examples/10-metatables/call.expected"
```

On Lua 5.4/5.5 the `__call` field may itself be a callable table. Lua 5.5 caps
such chains at 15 objects; LuaJIT does not support chains at all.

## `__close`: deterministic cleanup (Lua 5.4+)

A local declared `<close>` must hold a value with a `__close` metamethod (or
`nil`/`false`). When the variable goes out of scope (normal end of block,
`break`, `return`, `goto`, or an **error**), Lua calls `__close(value, err)`.
Several variables close in reverse order, like C++ destructors:

```lua title="examples/10-metatables/close.lua"
--8<-- "examples/10-metatables/close.lua"
```

```text
--8<-- "examples/10-metatables/close.expected"
```

!!! info "Version difference"
    `<close>` and `__close` exist in Lua 5.4 and 5.5 only. On LuaJIT, use
    `pcall` plus explicit cleanup, or a "with" helper:
    `with(resource, function(r) ... end)` that closes in all cases (Lesson 13).

## Protecting metatables

```lua title="examples/10-metatables/protect.lua"
--8<-- "examples/10-metatables/protect.lua"
```

```text
--8<-- "examples/10-metatables/protect.expected"
```

All strings share one metatable whose `__index` is the `string` table, which is
why `s:upper()` works. From Lua code you can only set the metatable of tables;
other types need `debug.setmetatable` or the C API.

## Hands-on exercises

??? example "Exercise 1: default values"
    Write `with_default(v)` that returns a table in which any missing key reads as
    `v`. Use it to count letters without `or 0`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/10-metatables/ex1_default.lua"
        ```
        ```text
        --8<-- "examples/10-metatables/ex1_default.expected"
        ```

??? example "Exercise 2: read-only tables"
    Write `readonly(t)` returning a view that can be read but not modified, and
    whose metatable cannot be inspected or replaced.

    ??? success "Solution"
        ```lua
        --8<-- "examples/10-metatables/ex2_readonly.lua"
        ```
        ```text
        --8<-- "examples/10-metatables/ex2_readonly.expected"
        ```
        `pairs` on the proxy sees nothing, because the proxy is empty. On 5.4/5.5
        you can add a `__pairs` metamethod that iterates over `t`.

??? example "Exercise 3: complex numbers"
    Implement complex numbers with `+`, `*`, `==` and `tostring`, allowing mixed
    real/complex arithmetic such as `1 + i`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/10-metatables/ex3_complex.lua"
        ```
        ```text
        --8<-- "examples/10-metatables/ex3_complex.expected"
        ```

??? example "Exercise 4: access logger"
    Write `track(t, log)` that returns a proxy recording every read and write of `t`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/10-metatables/ex4_tracker.lua"
        ```
        ```text
        --8<-- "examples/10-metatables/ex4_tracker.expected"
        ```

??? example "Exercise 5: scope timer (Lua 5.4+)"
    Write `scope_timer(label, report)` for use as a `<close>` variable, reporting
    how long its scope took. Inject the clock so the output is deterministic.

    ??? success "Solution"
        ```lua
        --8<-- "examples/10-metatables/ex5_timer.lua"
        ```
        ```text
        --8<-- "examples/10-metatables/ex5_timer.expected"
        ```

## Quiz

??? question "Q1. When is `__index` consulted?"
    Only when the key is absent from the table itself (the raw lookup gives `nil`).
    Existing keys never trigger it.

??? question "Q2. What is the difference between `t[k] = v` and `rawset(t, k, v)` when `t` has `__newindex`?"
    `t[k] = v` calls `__newindex` if `k` is absent; `rawset` always stores
    directly, skipping metamethods.

??? question "Q3. A type defines `__lt` but not `__le`. What does `a <= b` do on Lua 5.4, 5.5 and LuaJIT?"
    5.4 (default build) and LuaJIT compute `not (b < a)`; 5.5 raises
    "attempt to compare two table values".

??? question "Q4. In what order are three `<close>` variables in one block closed?"
    In reverse order of declaration, like C++ destructors.

??? question "Q5. Why does `error(msg, 2)` make sense inside `__newindex`?"
    Level 2 attributes the error to the code that performed the assignment rather
    than to the metamethod itself, so the message points at the user's line.
