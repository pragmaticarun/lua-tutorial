# 7. Patterns

--8<-- "includes/badges/07-patterns.md"

!!! abstract "What you will be able to do after this lesson"
    - Read and write Lua patterns, and know where they differ from regular expressions.
    - Use `find`, `match`, `gmatch` and `gsub`, with captures, position captures and back-references.
    - Use `gsub` with a table or a function as the replacement.
    - Parse real text (logs, `ffprobe` output, subtitles) with a few lines of code.

## Intuition: regex-lite, on purpose

A full POSIX or PCRE regex engine is larger than the whole Lua interpreter. Lua's
authors instead wrote a **pattern matcher of a few hundred lines of C** that covers most
day-to-day text processing. The price: no alternation (`a|b`), no `{n,m}` counts,
and quantifiers apply to a **single character class**, never to a group.

The mental model:

| You want | Regex | Lua pattern |
|---|---|---|
| Escape character | `\` | `%` (so `%.` is a literal dot, `%%` a literal percent) |
| Digit / letter / space | `\d` `[A-Za-z]` `\s` | `%d` `%a` `%s` |
| Word character | `\w` (includes `_`) | `%w` (no `_`!), so use `[%w_]` |
| Non-digit | `\D` | `%D` (upper-case = complement) |
| Lazy repetition | `.*?` | `.-` |
| Balanced `(...)` | (not possible) | `%b()` |
| Word boundary | `\b` | `%f[%w]` (frontier) |
| Alternation, groups with quantifiers | `(ab)+`, `a|b` | not supported: use several patterns or code |

Classes: `%a` letters, `%d` digits, `%l` lower-case, `%u` upper-case, `%s` space,
`%w` alphanumerics, `%x` hex digits, `%p` punctuation, `%c` control characters,
`%g` printable except space. Quantifiers: `*` (0+, greedy), `+` (1+, greedy),
`-` (0+, lazy), `?` (0 or 1). Anchors: `^` and `$`.

## The four functions

```lua title="examples/07-patterns/basics.lua"
--8<-- "examples/07-patterns/basics.lua"
```

```text
--8<-- "examples/07-patterns/basics.expected"
```

- `s:find(p [, init [, plain]])` returns start and end indices (plus captures).
- `s:match(p [, init])` returns the captures, or the whole match if there are none.
- `s:gmatch(p)` returns an iterator over all matches, for use in a generic `for`.
- `s:gsub(p, repl [, n])` returns the new string **and** the number of replacements.

## Classes, sets and quantifiers

```lua title="examples/07-patterns/classes.lua"
--8<-- "examples/07-patterns/classes.lua"
```

```text
--8<-- "examples/07-patterns/classes.expected"
```

Notice `%-?`: `-` is a quantifier, so a literal minus sign must be escaped.

### Greedy vs lazy

```lua title="examples/07-patterns/greedy.lua"
--8<-- "examples/07-patterns/greedy.lua"
```

```text
--8<-- "examples/07-patterns/greedy.expected"
```

## Captures

Parentheses capture. An empty capture `()` captures the **position**, and `%1`
inside the pattern refers back to the first capture's text.

```lua title="examples/07-patterns/captures.lua"
--8<-- "examples/07-patterns/captures.lua"
```

```text
--8<-- "examples/07-patterns/captures.expected"
```

## `gsub` with strings, tables and functions

The replacement can be a string (with `%0`–`%9` for captures), a **table** (the
first capture is used as a key), or a **function** (called with the captures). If
the table lookup or function returns `nil` or `false`, the original text is kept.

```lua title="examples/07-patterns/gsub_fn.lua"
--8<-- "examples/07-patterns/gsub_fn.lua"
```

```text
--8<-- "examples/07-patterns/gsub_fn.expected"
```

!!! tip "Wrap `gsub` in parentheses"
    `gsub` returns two values. `print(s:gsub(...))` prints the count too, and
    `table.insert(t, s:gsub(...))` fails because it receives three arguments.
    `(s:gsub(...))` truncates to one value.

## Frontier patterns: word boundaries

`%f[set]` matches the empty position where the previous character is **not** in
`set` and the next one is. `%f[%a]...%f[%A]` therefore means "a whole word":

```lua title="examples/07-patterns/frontier.lua"
--8<-- "examples/07-patterns/frontier.lua"
```

```text
--8<-- "examples/07-patterns/frontier.expected"
```

## Worked example: parsing `ffprobe` output

Real parsing is usually a loop over lines plus one `match` per field:

```lua title="examples/07-patterns/parse_stream.lua"
--8<-- "examples/07-patterns/parse_stream.lua"
```

```text
--8<-- "examples/07-patterns/parse_stream.expected"
```

!!! note "For C++/Rust developers"
    Lua patterns are backtracking matchers like `std::regex`, without its
    compile step or its syntax. There is no pattern compilation cache to manage, and for
    typical one-line patterns they are fast. They are **not** linear-time like
    Rust's `regex` crate: a pattern such as `^(.-)%s*$` on a long line of spaces can
    go quadratic (see Exercise 2). When you need a real grammar, use LPeg
    (a PEG library by Lua's author), which you will meet in later parts.

!!! info "Version notes"
    All patterns in this lesson behave identically on 5.5, 5.4 and LuaJIT 2.1.
    Lua 5.1's manual did not document `%f` or `%g`, but LuaJIT supports both.
    One trap found while testing this course: LuaJIT accepts a literal `"\0"` in
    a pattern but **not inside a set** (`"[\0]"` raises "malformed pattern");
    Lua 5.4/5.5 accept both.

    ```lua title="examples/07-patterns/nul_pattern.lua"
    --8<-- "examples/07-patterns/nul_pattern.lua"
    ```
    === "Lua 5.5 / 5.4"
        ```text
        --8<-- "examples/07-patterns/nul_pattern.expected"
        ```
    === "LuaJIT 2.1"
        ```text
        --8<-- "examples/07-patterns/nul_pattern.jit.expected"
        ```

## Hands-on exercises

??? example "Exercise 1: hashtags"
    Extract all hashtags (letters, digits, underscore) from a post. A lone `#` is not a tag.

    ??? success "Solution"
        ```lua
        --8<-- "examples/07-patterns/ex1_hashtags.lua"
        ```
        ```text
        --8<-- "examples/07-patterns/ex1_hashtags.expected"
        ```

??? example "Exercise 2: trim"
    Write `trim(s)`. Then write a version that avoids backtracking on long runs of whitespace.

    ??? success "Solution"
        ```lua
        --8<-- "examples/07-patterns/ex2_trim.lua"
        ```
        ```text
        --8<-- "examples/07-patterns/ex2_trim.expected"
        ```
        In `^%s*(.-)%s*$`, the lazy `.-` retries `%s*$` at every position, which
        is O(n²) for a long string of spaces. `trim_fast` finds the first
        non-space position with a position capture and then matches greedily to
        the last non-space character (`.*%S`).

??? example "Exercise 3: colours"
    Validate `#RRGGBB` strings and return the three components as numbers, or `nil` plus an error.

    ??? success "Solution"
        ```lua
        --8<-- "examples/07-patterns/ex3_color.lua"
        ```
        ```text
        --8<-- "examples/07-patterns/ex3_color.expected"
        ```

??? example "Exercise 4: SRT timestamps"
    Parse `00:01:02,345 --> 00:01:04,000` into start and end times in milliseconds.

    ??? success "Solution"
        ```lua
        --8<-- "examples/07-patterns/ex4_srt.lua"
        ```
        ```text
        --8<-- "examples/07-patterns/ex4_srt.expected"
        ```

??? example "Exercise 5: split"
    Write `split(s, sep)` that splits on a literal separator (which may contain
    pattern characters such as `.`) and keeps empty fields.

    ??? success "Solution"
        ```lua
        --8<-- "examples/07-patterns/ex5_split.lua"
        ```
        ```text
        --8<-- "examples/07-patterns/ex5_split.expected"
        ```

## Quiz

??? question "Q1. How do you match a literal `.` or `%` in a pattern?"
    Escape with `%`: `%.` and `%%`. (Or use `find` with `plain = true`.)

??? question "Q2. What is the difference between `.*` and `.-`?"
    Both match any sequence; `.*` is greedy (longest), `.-` is lazy (shortest).

??? question "Q3. How would you match `cat` or `dog`?"
    Not with one pattern: Lua has no alternation. Try two patterns, or match
    `%a+` and check the capture against a set `{cat = true, dog = true}`.

??? question "Q4. What does `(\"abc\"):match(\"()b()\")` return?"
    `2  3`: position captures return the index before and after `b`.

??? question "Q5. In `s:gsub(\"%$(%w+)\", vars)`, what happens for a name missing from `vars`?"
    The lookup returns `nil`, so the match is left unchanged in the output.
