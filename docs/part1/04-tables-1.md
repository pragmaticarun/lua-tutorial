# 4. Tables I: Arrays, Dictionaries and the Length Operator

--8<-- "includes/badges/04-tables-1.md"

!!! abstract "What you will be able to do after this lesson"
    - Use one table as an array, as a hash map, or both.
    - Understand reference semantics, identity equality and shallow copies.
    - Know precisely what `#t` means, and why "holes" give different answers on different interpreters.

## Intuition: one associative array to rule them all

Lua has exactly one compound data structure: the **table**, an associative array
from any non-nil key to any non-nil value. Arrays, maps, records, objects, modules,
namespaces and even the global environment are all tables.

Internally each table has two parts: an **array part** (a dense C array for keys
`1..n`) and a **hash part** for everything else. Lua moves keys between them as the
table grows, so `t[i]` on a dense sequence is as fast as indexing a `std::vector`,
while `t.name` is a hash lookup. You do not choose the representation; you choose
the keys.

!!! note "For C++/Rust developers"
    A table is like `HashMap<Value, Value>` with a built-in `Vec` fast path, shared
    via something like `Rc<RefCell<..>>`: tables are always passed **by reference**,
    and mutation through any reference is visible to all. There are no value-type
    aggregates in Lua.

## Tables as arrays

By convention arrays start at **index 1**. A table whose positive integer keys are
exactly `1..n` is called a **sequence**, and `#t` returns `n`.

```lua title="examples/04-tables-1/arrays.lua"
--8<-- "examples/04-tables-1/arrays.lua"
```

```text
--8<-- "examples/04-tables-1/arrays.expected"
```

`table.insert(t, pos, v)` and `table.remove(t, pos)` shift elements, so they are
O(n) like `vector::insert`. Appending with `t[#t + 1] = v` or `table.insert(t, v)`
is amortised O(1).

## Tables as dictionaries

```lua title="examples/04-tables-1/dicts.lua"
--8<-- "examples/04-tables-1/dicts.lua"
```

```text
--8<-- "examples/04-tables-1/dicts.expected"
```

Key facts:

- `t.name` is sugar for `t["name"]`; use brackets for keys that are not identifiers.
- Assigning `nil` deletes a key. There is no separate "contains"; `t[k] ~= nil` is the test.
- Float keys with an integral value are converted to integers, so `t[1]` and `t[1.0]` are the same slot. Strings are never converted: `t[1]` and `t["1"]` are different keys.
- Tables, functions and booleans can be keys (by identity), which is very handy for sets of objects.

## Reference semantics

```lua title="examples/04-tables-1/references.lua"
--8<-- "examples/04-tables-1/references.lua"
```

```text
--8<-- "examples/04-tables-1/references.expected"
```

`==` on tables compares identity (unless an `__eq` metamethod says otherwise,
Lesson 10). There is no built-in deep copy or deep equality.

## The length operator and the "holes" trap

The reference manual defines `#t` as returning **a border**: any index `n` such
that `t[n] ~= nil` and `t[n+1] == nil` (or `0` if `t[1] == nil`). For a proper
sequence there is exactly one border, so `#t` is well defined. When the table has
**holes** (`nil`s between non-nil values), there are several borders, and
**any of them** may be returned.

That is not a theoretical concern. Here is the same program on our three interpreters:

```lua title="examples/04-tables-1/holes.lua"
--8<-- "examples/04-tables-1/holes.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/04-tables-1/holes.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/04-tables-1/holes.5.4.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/04-tables-1/holes.jit.expected"
    ```

!!! warning "Surprise: Lua 5.5 answers differently"
    Lua 5.5 reimplemented how tables store their array part, and its `#` often
    returns the *first* border where Lua 5.4 returned the last slot of the array
    part. Every answer above is correct according to the manual. Code that
    "worked" with holes on 5.4 can silently change behaviour on 5.5.

The rules that keep you safe:

1. Never put `nil` in an array you will measure with `#`, iterate with `ipairs`, or pass to `table.*`.
2. To remove an element, use `table.remove`, which shifts the rest down.
3. If `nil` is a legitimate value, carry the count yourself in an `n` field:

```lua title="examples/04-tables-1/pack_n.lua"
--8<-- "examples/04-tables-1/pack_n.lua"
```

```text
--8<-- "examples/04-tables-1/pack_n.expected"
```

`select("#", ...)` counts the arguments including trailing `nil`s. Lesson 8 covers
varargs and `table.pack` properly.

## Hands-on exercises

??? example "Exercise 1: reverse in place"
    Write `reverse(t)` that reverses a sequence in place without a temporary
    variable, and returns it.

    ??? success "Solution"
        ```lua
        --8<-- "examples/04-tables-1/ex1_reverse.lua"
        ```
        ```text
        --8<-- "examples/04-tables-1/ex1_reverse.expected"
        ```

??? example "Exercise 2: word frequencies"
    Count the words in a sentence and print the three most common. Make the output
    deterministic even when two words have the same count.

    ??? success "Solution"
        ```lua
        --8<-- "examples/04-tables-1/ex2_wordfreq.lua"
        ```
        ```text
        --8<-- "examples/04-tables-1/ex2_wordfreq.expected"
        ```
        `gmatch("%a+")` iterates over runs of letters; patterns are Lesson 7.

??? example "Exercise 3: invert a map"
    Turn `{ ok = 200, not_found = 404, teapot = 418 }` into a lookup from code to name.

    ??? success "Solution"
        ```lua
        --8<-- "examples/04-tables-1/ex3_invert.lua"
        ```
        ```text
        --8<-- "examples/04-tables-1/ex3_invert.expected"
        ```

??? example "Exercise 4: compact a sparse array"
    Given an array with holes and the number of slots it was meant to have, build a
    new sequence without the holes.

    ??? success "Solution"
        ```lua
        --8<-- "examples/04-tables-1/ex4_compact.lua"
        ```
        ```text
        --8<-- "examples/04-tables-1/ex4_compact.expected"
        ```
        Note the function needs `n` from the caller: with holes, `#sparse` could be
        1, 3 or 6 depending on the interpreter.

## Quiz

??? question "Q1. After `local a = {1, 2}; local b = a; b[1] = 9`, what is `a[1]`?"
    `9`. Assignment copies the reference; `a` and `b` are the same table.

??? question "Q2. Are `t[1]`, `t[1.0]` and `t[\"1\"]` the same slot?"
    `t[1]` and `t[1.0]` are the same (integral float keys are normalised to
    integers). `t["1"]` is a different key.

??? question "Q3. What is a *border*, and why does it matter for `#`?"
    An index `n` with `t[n] ~= nil` and `t[n+1] == nil` (or 0 when `t[1]` is nil).
    `#t` returns *some* border; a sequence has only one, but a table with holes has
    several, so the result is unspecified.

??? question "Q4. How do you delete a key from a table?"
    Assign `nil` to it: `t.key = nil`. For arrays, use `table.remove(t, i)` so the
    elements after it shift down and no hole is left.

??? question "Q5. How do you count the entries in a dictionary-style table?"
    Loop with `pairs` and count. `#` only measures the sequence part.
