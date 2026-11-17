# 5. Tables II: Records, Sets, Queues, Matrices and the `table` Library

--8<-- "includes/badges/05-tables-2.md"

!!! abstract "What you will be able to do after this lesson"
    - Model structs, sets, queues and matrices with plain tables.
    - Use `table.concat`, `insert`, `remove`, `sort`, `unpack` and `move` correctly and portably.
    - Preallocate tables with Lua 5.5's `table.create` or LuaJIT's `table.new`.

## Intuition: data structures are conventions over one primitive

Lesson 4 showed the mechanics of tables. This lesson is about **idioms**: since
Lua gives you one primitive, each data structure is a *convention* on how you use
keys. Once you see the convention, you can write any structure in a few lines,
and you can read other people's Lua code fluently.

| Structure | Convention |
|---|---|
| Record / struct | String keys for fields: `p.x`, `p.y` |
| Array / list | Integer keys `1..n` |
| Set | Members are keys, values are `true` |
| Queue / deque | Integer keys between two moving indices `first..last` |
| Matrix | Array of row arrays: `m[i][j]` |

## Records

```lua title="examples/05-tables-2/records.lua"
--8<-- "examples/05-tables-2/records.lua"
```

```text
--8<-- "examples/05-tables-2/records.expected"
```

The call `new_clip { title = "outro" }` uses Lua's call sugar: a function applied
to a single table constructor (or string literal) needs no parentheses. This is
how many Lua DSLs (LuaRocks rockspecs, premake, xmake) get their declarative look.

!!! note "For C++/Rust developers"
    There is no struct declaration, so nothing stops you from misspelling a field
    (`clip.titel` reads `nil`). Constructor functions with `assert`s, like
    `new_clip`, are the cheap fix; metatables (Lesson 10) let you make unknown
    fields an error.

## Sets

```lua title="examples/05-tables-2/sets.lua"
--8<-- "examples/05-tables-2/sets.lua"
```

```text
--8<-- "examples/05-tables-2/sets.expected"
```

## Queues and deques

`table.insert(t, 1, v)` and `table.remove(t, 1)` shift every element, which makes
a naïve queue O(n). Keep two indices instead; keys are allowed to go to zero or
negative:

```lua title="examples/05-tables-2/queue.lua"
--8<-- "examples/05-tables-2/queue.lua"
```

```text
--8<-- "examples/05-tables-2/queue.expected"
```

Note the style: functions stored in a table `Deque` that take the object as their
first argument. That is half of Lua's object system; Lesson 11 adds the `:`
syntax and metatables to finish the job.

## Matrices

```lua title="examples/05-tables-2/matrix.lua"
--8<-- "examples/05-tables-2/matrix.lua"
```

```text
--8<-- "examples/05-tables-2/matrix.expected"
```

!!! tip "Performance note"
    An array of rows means one table per row. For large numeric grids (images,
    audio buffers) a single flat array indexed by `(i - 1) * cols + j` has better
    locality, and on LuaJIT an FFI array (`ffi.new("float[?]", n)`, Lesson 19) is
    far better still.

## The `table` library

```lua title="examples/05-tables-2/tablelib.lua"
--8<-- "examples/05-tables-2/tablelib.lua"
```

```text
--8<-- "examples/05-tables-2/tablelib.expected"
```

| Function | Notes |
|---|---|
| `table.concat(t [, sep [, i [, j]]])` | Joins strings/numbers. Much faster than `..` in a loop. |
| `table.insert(t, [pos,] v)` / `table.remove(t [, pos])` | Shift elements; O(n) except at the end. |
| `table.sort(t [, less])` | In-place quicksort-style sort. **Not stable**, and `less` must be a strict weak ordering (never return `true` for equal elements) or sorting can fail with "invalid order function for sorting". |
| `table.unpack(t [, i [, j]])` | `unpack` in Lua 5.1 and LuaJIT. Use `local unpack = table.unpack or unpack`. |
| `table.pack(...)` | Returns `{n = select("#", ...), ...}`. Not in LuaJIT (Lesson 8 shows a portable version). |
| `table.move(a1, f, e, t [, a2])` | Copy a range, handles overlap. Lua 5.3+, also LuaJIT 2.1. |
| `table.create(narr [, nrec])` | **Lua 5.5 only.** Preallocates. |

!!! info "Version difference: preallocation"
    Lua 5.5 added `table.create`. LuaJIT has had an equivalent extension module,
    `table.new`, plus `table.clear` for emptying a table while keeping its memory.
    Lua 5.4 has neither; the C API's `lua_createtable` is the only way there.

    === "Lua 5.5"
        ```lua title="examples/05-tables-2/prealloc.lua"
        --8<-- "examples/05-tables-2/prealloc.lua"
        ```
        ```text
        --8<-- "examples/05-tables-2/prealloc.expected"
        ```
    === "LuaJIT 2.1"
        ```lua title="examples/05-tables-2/prealloc_jit.lua"
        --8<-- "examples/05-tables-2/prealloc_jit.lua"
        ```
        ```text
        --8<-- "examples/05-tables-2/prealloc_jit.expected"
        ```

## Hands-on exercises

??? example "Exercise 1: ring buffer"
    Implement a fixed-capacity ring buffer that keeps the last N values (say,
    frame times in milliseconds) and can return them oldest-first.

    ??? success "Solution"
        ```lua
        --8<-- "examples/05-tables-2/ex1_ring.lua"
        ```
        ```text
        --8<-- "examples/05-tables-2/ex1_ring.expected"
        ```

??? example "Exercise 2: transpose"
    Write `transpose(m)` for a non-square matrix.

    ??? success "Solution"
        ```lua
        --8<-- "examples/05-tables-2/ex2_transpose.lua"
        ```
        ```text
        --8<-- "examples/05-tables-2/ex2_transpose.expected"
        ```

??? example "Exercise 3: group by"
    Group a list of file records by codec and print each group, in sorted order.

    ??? success "Solution"
        ```lua
        --8<-- "examples/05-tables-2/ex3_groupby.lua"
        ```
        ```text
        --8<-- "examples/05-tables-2/ex3_groupby.expected"
        ```

??? example "Exercise 4: stable sort"
    `table.sort` is not stable. Build `stable_sort(list, less)` that keeps equal
    elements in their original order.

    ??? success "Solution"
        ```lua
        --8<-- "examples/05-tables-2/ex4_stable.lua"
        ```
        ```text
        --8<-- "examples/05-tables-2/ex4_stable.expected"
        ```
        Decorate-sort-undecorate: the original index becomes the tie-breaker.

## Quiz

??? question "Q1. How do you represent the set {\"a\", \"b\"} in Lua, and test membership?"
    `local s = { a = true, b = true }`, then `if s.a then`. Membership is an O(1) key lookup.

??? question "Q2. Why is `table.remove(q, 1)` a poor way to dequeue?"
    It shifts every remaining element down, so each dequeue is O(n). Use two
    indices (`first`, `last`) for O(1) operations.

??? question "Q3. Is `table.sort` stable? What else must its comparator guarantee?"
    It is not stable. The comparator must be a strict ordering: `less(a, a)` must be
    `false`, otherwise sorting can raise "invalid order function for sorting".

??? question "Q4. How do you call `unpack` portably across Lua 5.1/LuaJIT and 5.4/5.5?"
    `local unpack = table.unpack or unpack`.

??? question "Q5. What do Lua 5.5 `table.create(n)` and LuaJIT `table.new(n, 0)` do, and what does `#t` return right after?"
    They preallocate space for `n` array elements to avoid rehashing while
    filling. The table is still empty, so `#t` is `0`.
