# 6. Strings

--8<-- "includes/badges/06-strings.md"

!!! abstract "What you will be able to do after this lesson"
    - Explain why Lua strings are immutable byte arrays, and build large strings efficiently.
    - Use the core `string` functions, including negative indices and plain `find`.
    - Format output precisely with `string.format`.
    - Handle UTF-8 text with the `utf8` library (and without it on LuaJIT).
    - Read and write binary data with `string.pack` / `string.unpack`.

## Intuition: an immutable `[u8]` with a toolbox attached

A Lua string is an **immutable sequence of bytes** with a known length. It is not
NUL-terminated (it may contain `"\0"`), it has no encoding of its own, and every
"modifying" function returns a *new* string. Short strings are **interned**: the
VM keeps one copy of each, which makes string equality and table lookups with
string keys a pointer comparison.

All strings share a metatable whose `__index` is the `string` table, so
`s:upper()` is just `string.upper(s)`. That is the whole "string class".

!!! note "For C++/Rust developers"
    Think `Rc<[u8]>` rather than `std::string` or `String`: cheap to copy (a
    reference), impossible to mutate in place, and no UTF-8 guarantee (unlike Rust's
    `str`). The idiom that replaces `std::string::append` in a loop is to collect
    pieces in a table and call `table.concat` once, like `Vec<&str>::join`.

```lua title="examples/06-strings/immutable.lua"
--8<-- "examples/06-strings/immutable.lua"
```

```text
--8<-- "examples/06-strings/immutable.expected"
```

!!! warning "Why not `s = s .. piece` in a loop?"
    Each `..` creates a new string and copies both operands, so building an
    n-piece string that way is O(n²) in bytes copied. `table.concat` is O(n).
    Lesson 17 measures the difference.

## The `string` library

Indices are **1-based and inclusive**, and negative indices count from the end
(`-1` is the last byte), like Python slices but inclusive.

```lua title="examples/06-strings/strlib.lua"
--8<-- "examples/06-strings/strlib.lua"
```

```text
--8<-- "examples/06-strings/strlib.expected"
```

!!! danger "`find` uses patterns by default"
    `s:find(".")` matches *any* character, because `.` is a pattern. Pass
    `init, true` (`s:find(".", 1, true)`) for a plain substring search. Patterns
    are the topic of Lesson 7.

## `string.format`

`string.format` follows C's `printf`, with two Lua twists: `%s` calls `tostring`
on any value, and `%q` produces a quoted literal that Lua can read back.

```lua title="examples/06-strings/format.lua"
--8<-- "examples/06-strings/format.lua"
```

```text
--8<-- "examples/06-strings/format.expected"
```

`%d` requires a number with an exact integer value on Lua 5.4/5.5, while LuaJIT
silently truncates. Code that relies on the truncation breaks when you move to 5.4+;
wrap the value in `math.floor` when it may be fractional.

```lua title="examples/06-strings/format_d.lua"
--8<-- "examples/06-strings/format_d.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/06-strings/format_d.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/06-strings/format_d.jit.expected"
    ```

## UTF-8

`#s` counts **bytes**. Lua 5.3 added a small `utf8` library for code points:

```lua title="examples/06-strings/utf8_lib.lua"
--8<-- "examples/06-strings/utf8_lib.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/06-strings/utf8_lib.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/06-strings/utf8_lib.5.4.expected"
    ```

Note that `upper`/`lower` are byte-based and only change ASCII letters (the
result depends on the C locale, which is `"C"` by default), hence `CAFé`.
Real Unicode case mapping needs a library such as `luautf8`.

!!! info "Version difference: `utf8.offset` in Lua 5.5"
    Lua 5.5's `utf8.offset` returns **two** values: the first and the last byte of
    the character. Lua 5.4 returns only the first. That is why line 7 of the
    output above differs.

    ```lua title="examples/06-strings/utf8_offset55.lua"
    --8<-- "examples/06-strings/utf8_offset55.lua"
    ```
    ```text
    --8<-- "examples/06-strings/utf8_offset55.expected"
    ```

LuaJIT has no `utf8` library. The portable trick is a pattern that matches one
lead byte followed by its continuation bytes (`0x80`–`0xBF`):

```lua title="examples/06-strings/utf8_jit.lua"
--8<-- "examples/06-strings/utf8_jit.lua"
```

```text
--8<-- "examples/06-strings/utf8_jit.expected"
```

## Binary data

Because strings are byte arrays, they are also Lua's binary buffer type:

```lua title="examples/06-strings/binary.lua"
--8<-- "examples/06-strings/binary.lua"
```

```text
--8<-- "examples/06-strings/binary.expected"
```

Lua 5.3+ adds `string.pack` and `string.unpack`, a compact format language for
fixed-layout binary data (endianness `<`/`>`, `I4` unsigned 4-byte integer, `c4`
fixed 4-byte string, `z` zero-terminated string, `s4` length-prefixed string…).
Here we build and parse a WAV header:

```lua title="examples/06-strings/pack.lua"
--8<-- "examples/06-strings/pack.lua"
```

```text
--8<-- "examples/06-strings/pack.expected"
```

!!! note "For C++/Rust developers"
    `string.pack` is the Lua equivalent of `memcpy` into a packed struct, or of the
    `byteorder` crate. On LuaJIT, which lacks it, you would use the FFI to cast the
    string to a C struct pointer (Lesson 19), which is even faster.

## Hands-on exercises

??? example "Exercise 1: Title Case"
    Convert every word to Title Case: first letter upper-case, rest lower-case.

    ??? success "Solution"
        ```lua
        --8<-- "examples/06-strings/ex1_titlecase.lua"
        ```
        ```text
        --8<-- "examples/06-strings/ex1_titlecase.expected"
        ```
        `gsub` returns two values (the new string and the number of
        substitutions); the extra parentheses keep only the first.

??? example "Exercise 2: aligned report"
    Print a table of file names, durations and sizes (KiB) with aligned columns.

    ??? success "Solution"
        ```lua
        --8<-- "examples/06-strings/ex2_report.lua"
        ```
        ```text
        --8<-- "examples/06-strings/ex2_report.expected"
        ```

??? example "Exercise 3: reverse UTF-8 text (Lua 5.4+)"
    Write `utf8_reverse(s)` that reverses characters, not bytes, and show that
    `string.reverse` gives a different result.

    ??? success "Solution"
        ```lua
        --8<-- "examples/06-strings/ex3_utf8_reverse.lua"
        ```
        ```text
        --8<-- "examples/06-strings/ex3_utf8_reverse.expected"
        ```

??? example "Exercise 4: hex dump"
    Write a hex dump showing offset, hex bytes and printable ASCII, 8 bytes per row.

    ??? success "Solution"
        ```lua
        --8<-- "examples/06-strings/ex4_hexdump.lua"
        ```
        ```text
        --8<-- "examples/06-strings/ex4_hexdump.expected"
        ```

??? example "Exercise 5: walk binary chunks (Lua 5.4+)"
    A file is a list of chunks: a 4-character tag, a big-endian 32-bit length,
    then the payload (like MP4 boxes). Walk the chunks with `string.unpack`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/06-strings/ex5_unpack.lua"
        ```
        ```text
        --8<-- "examples/06-strings/ex5_unpack.expected"
        ```
        `string.unpack` returns the next read position as its last result, which
        makes cursor-style parsing easy.

## Quiz

??? question "Q1. What does `(\"hello\"):sub(-3)` return?"
    `"llo"`: negative indices count from the end, and the range is inclusive.

??? question "Q2. Why is `s = s .. x` inside a long loop slow, and what is the fix?"
    Each concatenation allocates a new string and copies all previous bytes,
    giving O(n²) work. Collect pieces in a table and `table.concat` them once.

??? question "Q3. `#\"☕\"` is 3. Why?"
    `#` counts bytes, and U+2615 takes 3 bytes in UTF-8. `utf8.len("☕")` is 1.

??? question "Q4. How do you search for a literal `.` in a string?"
    `s:find(".", 1, true)` (plain search), or escape it in a pattern: `s:find("%.")`.

??? question "Q5. Which Lua 5.4+ functions read and write binary structs, and what is the LuaJIT alternative?"
    `string.pack` and `string.unpack`. On LuaJIT, use the FFI (`ffi.cast` /
    `ffi.string`) or manual `string.byte` arithmetic.
