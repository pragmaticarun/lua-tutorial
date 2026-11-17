# 8. Functions

--8<-- "includes/badges/08-functions.md"

!!! abstract "What you will be able to do after this lesson"
    - Treat functions as values: store, pass, return and compare them.
    - Return multiple results and predict exactly how they are adjusted.
    - Emulate named and optional arguments with a table.
    - Write variadic functions with `...`, `select`, `table.pack`, and Lua 5.5 named varargs.
    - Use proper tail calls, and write recursive local functions correctly.

## Intuition: a function is just another value

`function add(a, b) return a + b end` is **sugar for an assignment**:
`add = function(a, b) return a + b end`. The expression `function ... end`
creates a value of type `function` (a *closure*, Lesson 9), and the statement
binds it to a name. Everything else follows: functions can live in tables, be
passed to other functions, returned, and compared by identity.

```lua title="examples/08-functions/firstclass.lua"
--8<-- "examples/08-functions/firstclass.lua"
```

```text
--8<-- "examples/08-functions/firstclass.expected"
```

!!! note "For C++/Rust developers"
    Every Lua function behaves like a heap-allocated `std::function` / `Box<dyn Fn>`.
    Lua has no overloading and no static argument checks: missing arguments
    are `nil`, extra ones are dropped. Validation is your job (`assert`, `type`).

## Multiple results

A function can return several values. The caller decides how many it keeps,
following one rule: **only the last expression in a list expands to all its
results; every other position is truncated to exactly one value.**

```lua title="examples/08-functions/multiret.lua"
--8<-- "examples/08-functions/multiret.lua"
```

```text
--8<-- "examples/08-functions/multiret.expected"
```

This is how Lua does error handling without exceptions: functions such as
`io.open` return `nil, message` on failure (Lesson 13).

!!! note "For C++/Rust developers"
    Multiple results are like returning `std::tuple` / a Rust tuple, but with
    automatic destructuring and no tuple object allocated. The truncation rule is
    the part that bites: `f(g())` passes all of `g`'s results, but `f(g(), 1)`
    passes only the first.

## Named and optional arguments

Lua has no keyword arguments, but a table argument plus the `f{...}` call sugar
gives you the same thing:

```lua title="examples/08-functions/named_args.lua"
--8<-- "examples/08-functions/named_args.lua"
```

```text
--8<-- "examples/08-functions/named_args.expected"
```

## Variadic functions

`...` in a parameter list collects the extra arguments. Inside the function, the
expression `...` produces them as a multiple-value list.

- `select("#", ...)` counts them, **including trailing `nil`s**.
- `select(i, ...)` returns arguments `i` through the end (negative `i` counts from the end).
- `table.pack(...)` stores them in a table with an `n` field (5.2+; not in LuaJIT).
- `table.unpack(t, 1, t.n)` turns them back into a list.

```lua title="examples/08-functions/varargs.lua"
--8<-- "examples/08-functions/varargs.lua"
```

```text
--8<-- "examples/08-functions/varargs.expected"
```

!!! tip "Performance"
    `select(i, ...)` in a loop copies the remaining arguments each time, so a loop
    over n arguments is O(n²). For more than a handful of arguments, pack them once.

### Lua 5.5: named vararg tables

Lua 5.5 lets you give the varargs a name. The name is a **read-only local**
bound to a table holding the extra arguments and their count in `n`, so you no
longer need `table.pack`:

```lua title="examples/08-functions/named_vararg.lua"
--8<-- "examples/08-functions/named_vararg.lua"
```

```text
--8<-- "examples/08-functions/named_vararg.expected"
```

!!! info "Version difference"
    `function f(...name)` is a syntax error before 5.5. For code that must run
    everywhere, keep using `local args = { n = select("#", ...), ... }`.

## Proper tail calls

A call of the form `return f(args)` is a **tail call**: Lua reuses the current
stack frame, so tail-recursive functions run in constant stack space. This is
guaranteed by the language (and implemented by LuaJIT too), unlike C++ where it
depends on the optimizer.

```lua title="examples/08-functions/tailcall.lua"
--8<-- "examples/08-functions/tailcall.lua"
```

```text
--8<-- "examples/08-functions/tailcall.expected"
```

`return (f(x))`, `return f(x) + 1` and `return x, f(x)` are **not** tail calls.

## Recursive local functions

`local function f` is sugar for `local f; f = function ...`, so `f` is already in
scope inside its own body. `local f = function ...` is not, and the recursive call
silently refers to a *global* `f`:

```lua title="examples/08-functions/local_function.lua"
--8<-- "examples/08-functions/local_function.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/08-functions/local_function.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/08-functions/local_function.jit.expected"
    ```

Error message wording differs between PUC-Rio Lua and LuaJIT. Never parse error
messages in code that has to be portable.

## Hands-on exercises

??? example "Exercise 1: map, filter, reduce"
    Write the three classic higher-order functions and use them to list the
    durations of at least a minute as `m:ss`, and the total.

    ??? success "Solution"
        ```lua
        --8<-- "examples/08-functions/ex1_mapfilter.lua"
        ```
        ```text
        --8<-- "examples/08-functions/ex1_mapfilter.expected"
        ```

??? example "Exercise 2: printf-style logger"
    Write `log(level, fmt, ...)` that drops messages below a threshold and
    formats the rest.

    ??? success "Solution"
        ```lua
        --8<-- "examples/08-functions/ex2_log.lua"
        ```
        ```text
        --8<-- "examples/08-functions/ex2_log.expected"
        ```

??? example "Exercise 3: min, max and average"
    Write a variadic `stats(...)` returning three results, or `nil, "no values"`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/08-functions/ex3_stats.lua"
        ```
        ```text
        --8<-- "examples/08-functions/ex3_stats.expected"
        ```

??? example "Exercise 4: compose"
    Write `compose(f, g, h, ...)` returning a function that computes `f(g(h(x)))`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/08-functions/ex4_compose.lua"
        ```
        ```text
        --8<-- "examples/08-functions/ex4_compose.expected"
        ```

??? example "Exercise 5: tail recursion"
    Write a tail-recursive `gcd(a, b)` and a tail-recursive `sum_to(n)` with an
    accumulator, and run `sum_to(2000000)`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/08-functions/ex5_gcd.lua"
        ```
        ```text
        --8<-- "examples/08-functions/ex5_gcd.expected"
        ```

## Quiz

??? question "Q1. Given `function f() return 1, 2 end`, what does `print(f(), f())` print?"
    `1  1  2`. The first call is not last in the list, so it is truncated to one value.

??? question "Q2. What is the difference between `select(\"#\", ...)` and `#{...}`?"
    `select("#", ...)` counts all arguments including trailing `nil`s; `#{...}` is a
    table length and is unreliable once `nil`s are involved.

??? question "Q3. Is `return 1 + f(x)` a tail call?"
    No. The addition runs after `f` returns, so the frame must be kept.

??? question "Q4. Why does `local fib = function(n) ... fib(n-1) ... end` fail?"
    The local `fib` is not in scope until after the statement, so the body refers
    to a global `fib`. Use `local function fib(n)`.

??? question "Q5. What does Lua 5.5's `function f(...args)` give you, and can you reassign `args`?"
    A read-only local holding the extra arguments as a table with an `n` field. Assigning to `args` is a compile error.
