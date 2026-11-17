# 14. Iterators and Coroutines

--8<-- "includes/badges/14-coroutines.md"

!!! abstract "What you will be able to do after this lesson"
    - Explain the generic `for` protocol and write stateless and stateful iterators.
    - Use coroutines: `create`, `resume`, `yield`, `status`, `wrap`, `close`.
    - Turn recursive algorithms into generators, and build producer/consumer pipelines.
    - Write a tiny cooperative scheduler, the core of every Lua event loop.

## Intuition: a function you can pause

A **coroutine** is a function with its own stack that can stop in the middle
(`coroutine.yield`) and later continue from exactly that point
(`coroutine.resume`). Only one runs at a time, and it runs until it chooses to
yield: this is *cooperative* multitasking, with no locks and no data races.

Iterators and coroutines belong together: an iterator is "give me the next value",
and a coroutine lets you write the producing side as a plain loop or recursion
that `yield`s each value.

!!! note "For C++/Rust developers"
    Lua coroutines are **stackful**: a yield can happen deep inside nested calls,
    unlike C++20 coroutines or Rust `async fn`, which are stackless state machines
    and need `co_await`/`.await` at every level. That makes them closer to
    Boost.Context fibers or goroutines without the parallelism. OpenResty, Neovim's
    async helpers and most Lua game engines build "async" APIs on them.

## The generic `for` protocol

`for vars in explist do` evaluates `explist` to three values: an iterator function
`f`, an invariant state `s`, and a control value `c`. Each iteration calls
`f(s, c)`, and the first result becomes the new control value; the loop stops when
it is `nil`. Iterators that keep all state in `s` and `c` are **stateless** and
allocate nothing per loop; `ipairs` and `pairs` (`next`) are stateless:

```lua title="examples/14-coroutines/for_protocol.lua"
--8<-- "examples/14-coroutines/for_protocol.lua"
```

```text
--8<-- "examples/14-coroutines/for_protocol.expected"
```

**Stateful** iterators are closures (Lesson 9) that remember their position:

```lua title="examples/14-coroutines/stateful_iter.lua"
--8<-- "examples/14-coroutines/stateful_iter.lua"
```

```text
--8<-- "examples/14-coroutines/stateful_iter.expected"
```

## Coroutine basics

`resume` passes values **into** the coroutine (as the function's arguments the
first time, then as the results of `yield`), and `yield` passes values **out** (as
the extra results of `resume`):

```lua title="examples/14-coroutines/basics.lua"
--8<-- "examples/14-coroutines/basics.lua"
```

```text
--8<-- "examples/14-coroutines/basics.expected"
```

A coroutine is `suspended`, `running`, `normal` (it resumed another coroutine and
is waiting) or `dead`.

## Generators with `coroutine.wrap`

`coroutine.wrap(f)` returns a function that resumes the coroutine each time it is
called and returns what it yields, which is exactly the shape of an iterator.
Recursive traversals become generators with no explicit stack:

```lua title="examples/14-coroutines/generators.lua"
--8<-- "examples/14-coroutines/generators.lua"
```

```text
--8<-- "examples/14-coroutines/generators.expected"
```

## Producer / consumer pipelines

Each stage pulls from the previous one, so data flows one item at a time with no
intermediate arrays: the structure of a media pipeline (demux → filter → mux).

```lua title="examples/14-coroutines/pipeline.lua"
--8<-- "examples/14-coroutines/pipeline.lua"
```

```text
--8<-- "examples/14-coroutines/pipeline.expected"
```

## A tiny scheduler

A scheduler is a loop that resumes whichever task should run next. Tasks yield
how long they want to sleep; the scheduler advances a virtual clock. Replace the
virtual clock with real time and `sleep` with "wait for this socket" and you have
the design of OpenResty's cosockets or a game engine's script runner.

```lua title="examples/14-coroutines/scheduler.lua"
--8<-- "examples/14-coroutines/scheduler.lua"
```

```text
--8<-- "examples/14-coroutines/scheduler.expected"
```

The crash of one task does not stop the others: `resume` returns `false, err`
instead of raising.

## Errors and the C-call boundary

```lua title="examples/14-coroutines/errors.lua"
--8<-- "examples/14-coroutines/errors.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/14-coroutines/errors.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/14-coroutines/errors.jit.expected"
    ```

- `resume` catches errors like `pcall`; `wrap` re-raises them in the caller.
- You can yield from inside `pcall` and from metamethods (5.2+ and LuaJIT).
- You **cannot** yield through a C function that calls back into Lua, such as
  `table.sort`'s comparator or a callback invoked by a C library, unless that C
  code uses the continuation API (Lesson 21).

## Closing coroutines (Lua 5.4+)

A suspended coroutine that is never resumed keeps its `<close>` variables open.
`coroutine.close` runs them and kills the coroutine. The generic `for` also
accepts a fourth value, a *closing value* that is closed when the loop ends,
including through `break`:

```lua title="examples/14-coroutines/close_co.lua"
--8<-- "examples/14-coroutines/close_co.lua"
```

```text
--8<-- "examples/14-coroutines/close_co.expected"
```

!!! info "Version notes"
    | | Lua 5.5 / 5.4 | LuaJIT 2.1 |
    |---|---|---|
    | `coroutine.close` | yes | no |
    | `coroutine.running()` in the main thread | the main coroutine, `true` | `nil` |
    | `coroutine.isyieldable` | yes | yes (backported) |
    | Yield across `pcall` and metamethods | yes | yes |
    | 4th "closing value" in generic `for` | yes | no |

    ```lua title="examples/14-coroutines/running.lua"
    --8<-- "examples/14-coroutines/running.lua"
    ```
    === "Lua 5.5 / 5.4"
        ```text
        --8<-- "examples/14-coroutines/running.expected"
        ```
    === "LuaJIT 2.1"
        ```text
        --8<-- "examples/14-coroutines/running.jit.expected"
        ```

## Hands-on exercises

??? example "Exercise 1: a stateless `range`"
    Write `range(start, stop, step)` as a stateless iterator (no closures).

    ??? success "Solution"
        ```lua
        --8<-- "examples/14-coroutines/ex1_range.lua"
        ```
        ```text
        --8<-- "examples/14-coroutines/ex1_range.expected"
        ```

??? example "Exercise 2: batches"
    Write a generator that yields an array in batches of `n` items, together with
    the index of the first item.

    ??? success "Solution"
        ```lua
        --8<-- "examples/14-coroutines/ex2_batches.lua"
        ```
        ```text
        --8<-- "examples/14-coroutines/ex2_batches.expected"
        ```

??? example "Exercise 3: a tokenizer generator"
    Tokenize `codec=av1; title='My Talk'; crf=30` into words, quoted strings and
    punctuation with a coroutine.

    ??? success "Solution"
        ```lua
        --8<-- "examples/14-coroutines/ex3_tokens.lua"
        ```
        ```text
        --8<-- "examples/14-coroutines/ex3_tokens.expected"
        ```

??? example "Exercise 4: interleave"
    Write `interleave(g1, g2, ...)` that takes values round-robin from several
    generators until all are exhausted.

    ??? success "Solution"
        ```lua
        --8<-- "examples/14-coroutines/ex4_interleave.lua"
        ```
        ```text
        --8<-- "examples/14-coroutines/ex4_interleave.expected"
        ```

??? example "Exercise 5: channels"
    Extend the scheduler idea with a `Channel` whose `receive` blocks the calling
    task until another task `send`s a value.

    ??? success "Solution"
        ```lua
        --8<-- "examples/14-coroutines/ex5_channels.lua"
        ```
        ```text
        --8<-- "examples/14-coroutines/ex5_channels.expected"
        ```

## Quiz

??? question "Q1. What three values does the explist of a generic `for` produce?"
    The iterator function, the invariant state and the initial control value.

??? question "Q2. What does `coroutine.resume(co, x)` return when `co` executes `coroutine.yield(1, 2)`?"
    `true, 1, 2`. And `x` becomes the result of the `yield` that resumed it (or the
    function's argument on the first resume).

??? question "Q3. What is the difference between `coroutine.wrap` and `coroutine.create`?"
    `wrap` returns a function that resumes the coroutine and re-raises errors;
    `create` returns a thread object that you resume yourself, getting `false, err`
    on errors.

??? question "Q4. Why does yielding inside a `table.sort` comparator fail?"
    The comparator is called from C code (`table.sort`), and a yield cannot cross a
    C-call boundary that does not support continuations.

??? question "Q5. Are Lua coroutines preemptive? Do they run in parallel?"
    Neither. They are cooperative and run one at a time on one OS thread; a
    coroutine runs until it yields, returns or raises.
