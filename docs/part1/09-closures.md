# 9. Closures and Upvalues

--8<-- "includes/badges/09-closures.md"

!!! abstract "What you will be able to do after this lesson"
    - Explain what a closure and an upvalue are, and how they differ from C++ lambda captures.
    - Use closures for private state, counters, factories and memoization.
    - Write callback-based code like the host APIs of mpv, Neovim and LÖVE expect.

## Intuition: functions that carry their variables with them

When a function refers to a local variable of an enclosing function, Lua keeps
that variable alive for as long as the inner function exists. The inner function
together with the variables it captured is a **closure**; each captured variable
is an **upvalue**.

The key point is that upvalues are captured **by reference**, as *variables*, not
as copies of values. Two closures created in the same call share the same
variable, and they can both read and update it, even after the outer function
has returned.

```lua title="examples/09-closures/counter.lua"
--8<-- "examples/09-closures/counter.lua"
```

```text
--8<-- "examples/09-closures/counter.expected"
```

Each call to `make_counter` creates a new `count` variable, so `by1` and `by10`
are independent.

!!! note "For C++/Rust developers"
    A Lua closure is like a C++ lambda that captures **by reference**, `[&]`, but
    without the dangling-reference bug: when the enclosing function returns, Lua
    moves the captured variable from the stack to the heap ("closing" the upvalue),
    and the closure keeps it alive. In Rust terms, it behaves like
    `move` capture of an `Rc<RefCell<T>>` shared by all closures created in that scope,
    with the garbage collector instead of reference counting.

## Shared upvalues: private state

Closures created in the same scope share their upvalues, which makes them a clean
way to hide state. Nothing outside can touch `level`:

```lua title="examples/09-closures/shared_upvalue.lua"
--8<-- "examples/09-closures/shared_upvalue.lua"
```

```text
--8<-- "examples/09-closures/shared_upvalue.expected"
```

This is the "privacy with closures" technique you will reuse in Lesson 11 (OOP).

## Closures in loops

The control variable of a `for` loop is a **fresh local for each iteration**, so
closures created in the loop capture different variables. A variable declared
outside the loop is one variable shared by all of them:

```lua title="examples/09-closures/loop_capture.lua"
--8<-- "examples/09-closures/loop_capture.lua"
```

```text
--8<-- "examples/09-closures/loop_capture.expected"
```

(JavaScript programmers know this bug from `var`; Lua's `for` behaves like
JavaScript's `let`.)

## Memoization

A cache kept in an upvalue turns an exponential recursive function into a linear one:

```lua title="examples/09-closures/memoize.lua"
--8<-- "examples/09-closures/memoize.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/09-closures/memoize.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/09-closures/memoize.jit.expected"
    ```

Note how `fib` is declared first and assigned afterwards, so the function body
can refer to the *memoized* `fib`, not the raw one. Also notice the LuaJIT output:
`fib(80)` exceeds 2^53, so as a double it prints in exponent form and has lost
its last digits. On 5.4/5.5 it is an exact 64-bit integer.

!!! warning "Memory"
    A cache in an upvalue lives as long as the closure. An unbounded cache keyed by
    tables keeps those tables alive forever; Lesson 16 shows weak tables that
    let the garbage collector drop entries.

## Callbacks

Host applications talk to Lua through callbacks. mpv calls your function on
property changes, Neovim on autocommands, LÖVE on every frame. Closures let each
callback carry the state it needs:

```lua title="examples/09-closures/callbacks.lua"
--8<-- "examples/09-closures/callbacks.lua"
```

```text
--8<-- "examples/09-closures/callbacks.expected"
```

!!! info "Version notes"
    Closure semantics are identical on Lua 5.1 through 5.5 and LuaJIT. LuaJIT's
    JIT compiler does have one caveat: creating closures (the `FNEW` bytecode) is
    not compiled in LuaJIT 2.1 and aborts a trace, so avoid creating closures
    inside hot loops on LuaJIT. Lesson 18 covers this.

## Hands-on exercises

??? example "Exercise 1: accumulator with reset"
    Write `make_acc(start)` returning a table with `add(x)` and `reset()`
    functions that share one running total.

    ??? success "Solution"
        ```lua
        --8<-- "examples/09-closures/ex1_accumulator.lua"
        ```
        ```text
        --8<-- "examples/09-closures/ex1_accumulator.expected"
        ```

??? example "Exercise 2: `once`"
    Write `once(f)`: the returned function calls `f` the first time only, and
    always returns `f`'s (possibly multiple) results.

    ??? success "Solution"
        ```lua
        --8<-- "examples/09-closures/ex2_once.lua"
        ```
        ```text
        --8<-- "examples/09-closures/ex2_once.expected"
        ```

??? example "Exercise 3: two-argument memoize"
    Memoize a function of two arguments. Avoid building string keys like
    `a .. "," .. b`, which conflate e.g. `1, "2,3"` and `"1,2", 3`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/09-closures/ex3_memo2.lua"
        ```
        ```text
        --8<-- "examples/09-closures/ex3_memo2.expected"
        ```

??? example "Exercise 4: throttle"
    Write `throttle(f, interval, clock)` that lets through at most one call per
    `interval`. Inject the clock so you can test it deterministically (a common
    trick for OSD updates in mpv scripts).

    ??? success "Solution"
        ```lua
        --8<-- "examples/09-closures/ex4_throttle.lua"
        ```
        ```text
        --8<-- "examples/09-closures/ex4_throttle.expected"
        ```

??? example "Exercise 5: an iterator from a closure"
    Write `range(from, to, step)` that returns a closure usable in a generic `for`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/09-closures/ex5_range.lua"
        ```
        ```text
        --8<-- "examples/09-closures/ex5_range.expected"
        ```
        A generic `for` keeps calling the iterator until it returns `nil`; Lesson 14
        shows stateless iterators that avoid allocating a closure.

## Quiz

??? question "Q1. What is an upvalue?"
    A local variable of an enclosing function that a closure refers to. The closure
    keeps it alive and accesses it by reference.

??? question "Q2. Two closures are created by the same call and both refer to `x`. One sets `x = 5`. What does the other see?"
    `5`. They share the same upvalue (the same variable), not copies.

??? question "Q3. Ten closures are created in `for i = 1, 10 do`. What does each return if it returns `i`?"
    Its own iteration's value, 1 through 10, because each iteration has a fresh `i`.

??? question "Q4. Why declare `local fib` before `fib = memoize(function(n) ... fib(n-1) ... end)`?"
    So the inner function's `fib` refers to the local that will hold the memoized
    version (an upvalue), rather than to an undefined global.

??? question "Q5. Is it safe to return a closure that captures a local from a function that has already returned?"
    Yes. Unlike a C++ lambda capturing by reference, Lua moves the variable off
    the stack when the scope ends, and the closure keeps it alive.
