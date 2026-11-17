# 3. Control Flow

--8<-- "includes/badges/03-control-flow.md"

!!! abstract "What you will be able to do after this lesson"
    - Write `if`, `while`, `repeat`, numeric `for` and generic `for` loops fluently.
    - Know exactly what the loop control variable is, and why Lua 5.5 makes it read-only.
    - Use `break`, and `goto` for `continue` and for leaving nested loops.

## Intuition: few constructs, each with one clear rule

Lua's control flow is deliberately small. There is no `switch`, no `continue` (in standard Lua), no
`do/while`, and no C-style three-part `for`. In exchange, each construct has one
crisp rule:

- **Blocks end with `end`** (or `until` for `repeat`). No braces, no significant indentation.
- **Conditions accept any value**; only `nil` and `false` are false (Lesson 2).
- **A numeric `for` computes its range once**, up front, like iterating a Rust `Range`.
- **A generic `for` calls an iterator function** until it returns `nil`.

## `if` / `elseif` / `else`

```lua title="examples/03-control-flow/if_elseif.lua"
--8<-- "examples/03-control-flow/if_elseif.lua"
```

```text
--8<-- "examples/03-control-flow/if_elseif.expected"
```

`elseif` is one word. Writing `else if` opens a *nested* `if` that needs its own `end`.

## `while` and `repeat`

```lua title="examples/03-control-flow/while_repeat.lua"
--8<-- "examples/03-control-flow/while_repeat.lua"
```

```text
--8<-- "examples/03-control-flow/while_repeat.expected"
```

The `repeat ... until cond` scoping rule is handy: `cond` may refer to locals
declared inside the loop body, so you do not have to hoist `done` above the loop.

!!! note "Why `math.floor(n / 2)` instead of `n // 2`?"
    `//` does not exist in LuaJIT. `math.floor` works everywhere, and in Lua 5.4/5.5
    it returns an **integer** when the result fits, so `n` never turns into a float.

## The numeric `for`

`for v = start, limit, step do ... end`, where `step` defaults to `1`.

```lua title="examples/03-control-flow/numeric_for.lua"
--8<-- "examples/03-control-flow/numeric_for.lua"
```

```text
--8<-- "examples/03-control-flow/numeric_for.expected"
```

!!! note "For C++/Rust developers"
    The numeric `for` behaves like `for i in (start..=limit).step_by(step)` in Rust,
    not like C's `for (init; cond; incr)`: the bounds are evaluated once and
    changing `limit` inside the body does nothing. The control variable is a
    new local scoped to the loop body, so it does not leak out, just like Rust.
    In Lua 5.4+, integer loops are also overflow-safe: the iteration count is
    computed in advance, so a loop up to `math.maxinteger` terminates.

If any of `start`, `limit` or `step` is a float, the loop runs over floats:

```lua title="examples/03-control-flow/float_for.lua"
--8<-- "examples/03-control-flow/float_for.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/03-control-flow/float_for.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/03-control-flow/float_for.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/03-control-flow/float_for.jit.expected"
    ```

!!! warning "Surprise: `io.write` and floats in Lua 5.4"
    In Lua 5.4, `print(1.0)` shows `1.0` but `io.write(1.0)` shows `1`: `io.write`
    formats numbers with `%.14g` directly instead of going through `tostring`.
    Lua 5.5 makes them consistent (`1.0` in both). LuaJIT has no floats-vs-integers
    distinction, so it shows `1`.

### Lua 5.5: the control variable is read-only

In Lua 5.4 and earlier you could assign to the loop variable inside the body (it
only changed your local copy, not the iteration). Lua 5.5 makes the control
variable of **both** kinds of `for` loop a constant, so the assignment is a
**compile error**:

```lua title="examples/03-control-flow/for_readonly.lua"
--8<-- "examples/03-control-flow/for_readonly.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/03-control-flow/for_readonly.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/03-control-flow/for_readonly.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/03-control-flow/for_readonly.jit.expected"
    ```

The 5.5 manual's advice: if you need to modify it, declare a local with the same
name inside the body (`local i = i * 10`). Code written that way works on every
version.

## The generic `for`

`for k, v in explist do ... end` repeatedly calls an **iterator function** and stops
when its first result is `nil`. The standard library supplies `ipairs` (array part,
in order) and `pairs` (all keys, unspecified order). Lesson 14 shows how to write
your own iterators.

```lua title="examples/03-control-flow/generic_for.lua"
--8<-- "examples/03-control-flow/generic_for.lua"
```

```text
--8<-- "examples/03-control-flow/generic_for.expected"
```

!!! danger "Never depend on `pairs` order"
    The traversal order of `pairs` depends on the table's internal layout and on
    the per-process hash seed. It can differ between runs, interpreters and
    versions. Collect and sort the keys when order matters, as above.

## `break` and `goto`

`break` leaves the innermost loop. There is no `continue`; since Lua 5.2 (and in
LuaJIT) you use `goto` with a label instead. Labels are written `::name::`.

```lua title="examples/03-control-flow/goto_continue.lua"
--8<-- "examples/03-control-flow/goto_continue.lua"
```

```text
--8<-- "examples/03-control-flow/goto_continue.expected"
```

!!! info "LuaJIT has a real `continue` now"
    LuaJIT 2.1 builds from July 2026 on accept a `continue` statement, backported
    from LuaJIT 3.0. It is not standard Lua and older LuaJIT builds reject it, so
    portable code should keep using `goto continue`.

`goto` cannot jump into a block, or into the scope of a local variable, so it
cannot create the spaghetti that gave it a bad name in C.

## Hands-on exercises

??? example "Exercise 1: FizzBuzz"
    Print FizzBuzz for 1..15 on one line, using `table.concat` to join the words.

    ??? success "Solution"
        ```lua
        --8<-- "examples/03-control-flow/ex1_fizzbuzz.lua"
        ```
        ```text
        --8<-- "examples/03-control-flow/ex1_fizzbuzz.expected"
        ```

??? example "Exercise 2: digit sum"
    Write `digit_sum(n)` with a `while` loop. Make sure the output shows integers
    (`10`, not `10.0`) on Lua 5.4/5.5 and still works on LuaJIT.

    ??? success "Solution"
        ```lua
        --8<-- "examples/03-control-flow/ex2_digits.lua"
        ```
        ```text
        --8<-- "examples/03-control-flow/ex2_digits.expected"
        ```
        Using `(n - d) / 10` would work too, but `/` produces floats, so Lua 5.4/5.5
        would print `10.0`.

??? example "Exercise 3: input validation with `repeat`"
    Keep reading lines from stdin until one is a positive number. Use
    `repeat ... until ok`, where `ok` is a local declared inside the body.

    ??? success "Solution"
        ```lua
        --8<-- "examples/03-control-flow/ex3_prompt.lua"
        ```
        Input:
        ```text
        --8<-- "examples/03-control-flow/ex3_prompt.input"
        ```
        Output (the prompts and answers share lines because stdin is a file):
        ```text
        --8<-- "examples/03-control-flow/ex3_prompt.expected"
        ```

??? example "Exercise 4: leave two loops at once"
    Find the first pair in `{3, 9, 14, 5, 11}` that sums to 16. Exit both loops as
    soon as you find it.

    ??? success "Solution"
        ```lua
        --8<-- "examples/03-control-flow/ex4_pair.lua"
        ```
        ```text
        --8<-- "examples/03-control-flow/ex4_pair.expected"
        ```

## Quiz

??? question "Q1. What does `for i = 1, n do n = n + 1 end` do?"
    It runs exactly the original `n` times: the limit is evaluated once, before
    the first iteration.

??? question "Q2. What happens in Lua 5.5 if a loop body does `i = i + 1` on its control variable?"
    Compile error: `attempt to assign to const variable 'i'`. In 5.4 and LuaJIT it
    compiles and only changes the body's copy. Use `local i = i + 1` instead.

??? question "Q3. How do you write `continue` in Lua?"
    Put a label just before the loop's `end` (`::continue::`) and `goto continue`.

??? question "Q4. Can the `until` condition of a `repeat` loop use a local declared inside the loop body?"
    Yes. That is a deliberate difference from `while`, and from C's `do { } while`.

??? question "Q5. Why can `for k, v in pairs(t)` print keys in a different order on another run?"
    `pairs` order follows the table's internal hash layout, which depends on
    insertion history, table size and a per-state hash seed. The language does not
    specify an order.
