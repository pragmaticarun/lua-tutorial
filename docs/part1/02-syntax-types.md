# 2. Syntax, Types and Values

--8<-- "includes/badges/02-syntax-types.md"

!!! abstract "What you will be able to do after this lesson"
    - Name Lua's eight types and predict what `type()` returns.
    - Reason about integers vs floats in Lua 5.4/5.5, and doubles in LuaJIT.
    - Use truthiness, `and`/`or` defaults, and avoid the `false` trap.
    - Make `local` a reflex, and use Lua 5.5 `global` declarations to turn typos into compile errors.

## Intuition: values have types, variables do not

In C++ or Rust, a *variable* has a type that the compiler checks. In Lua, a
variable is just a name bound to a **value**, and every value carries its own type
tag at run time. There are exactly eight types:

| Type | Examples | Notes |
|---|---|---|
| `nil` | `nil` | "No value". Reading a missing variable or table key gives `nil`. |
| `boolean` | `true`, `false` | |
| `number` | `42`, `3.14`, `0x1F` | Two subtypes in 5.3+: integer and float. |
| `string` | `"hi"`, `[[raw]]` | Immutable byte strings (can hold any bytes, including `\0`). |
| `table` | `{}`, `{1, 2, x = 3}` | The *only* data structure. Lessons 4–5. |
| `function` | `print`, `function() end` | First-class values. Lesson 8. |
| `thread` | `coroutine.create(f)` | Coroutines, not OS threads. Lesson 14. |
| `userdata` | `io.stdout` | Memory owned by C. Lessons 20–21. |

```lua title="examples/02-syntax-types/types.lua"
--8<-- "examples/02-syntax-types/types.lua"
```

```text
--8<-- "examples/02-syntax-types/types.expected"
```

!!! note "For C++/Rust developers"
    Think of every Lua value as a small tagged union, roughly
    `enum Value { Nil, Bool(bool), Int(i64), Float(f64), Str(Rc<str>), Table(Rc<..>), ... }`.
    Strings, tables, functions, threads and full userdata are **references** to
    garbage-collected objects; nil, booleans and numbers are copied by value.
    Assigning a table to another variable never copies it.

## Numbers: integer and float subtypes

Lua 5.3 split `number` into two subtypes that convert to each other automatically.
The operators decide which one you get:

- `+ - * // %` on two integers give an **integer** (with 64-bit wraparound on overflow).
- `/` and `^` always give a **float**.
- Integers and floats with the same mathematical value are equal: `1 == 1.0`.

```lua title="examples/02-syntax-types/numbers.lua"
--8<-- "examples/02-syntax-types/numbers.lua"
```

=== "Lua 5.5"
    ```text
    --8<-- "examples/02-syntax-types/numbers.expected"
    ```
=== "Lua 5.4"
    ```text
    --8<-- "examples/02-syntax-types/numbers.5.4.expected"
    ```

Things worth noticing:

- `-7 // 2` is `-4`, not `-3`: Lua's `//` **floors**, unlike C++/Rust integer
  division, which truncates toward zero. Likewise `-7 % 3` is `2` in Lua, `-1` in C++.
- `math.maxinteger + 1` silently wraps to `math.mininteger`, like Rust's
  `wrapping_add`, not like a panic in a debug build.
- Integer `1 // 0` raises an error; float division by zero gives `inf`.
- Strings are converted to numbers in arithmetic (`"10" + 1` is `11`), and numbers
  to strings in concatenation (`10 .. 20` is `"1020"`; the spaces stop the lexer
  from reading `10.` as a float).

### LuaJIT: one number type

LuaJIT follows Lua 5.1: every number is a double, and there is no `//` and no
`math.type`. Bitwise operations traditionally go through the `bit` library
(`bit.band`, `bit.lshift`…); builds of the 2.1 branch from July 2026 on also
accept the 5.3-style operators `& | ~ << >>`
([details](../version-differences.md#luajit-21-syntax-backports)). LuaJIT adds
64-bit integers through its FFI as boxed `cdata` values.

```lua title="examples/02-syntax-types/numbers_jit.lua"
--8<-- "examples/02-syntax-types/numbers_jit.lua"
```

```text
--8<-- "examples/02-syntax-types/numbers_jit.expected"
```

!!! warning "Version difference: how floats print"
    Lua 5.5 changed the float-to-string conversion. It first tries 14
    significant digits (`%.14g`, as before) and, **if the text would not read back
    as the same number, it reprints with 17 digits**. Lua 5.4 and LuaJIT always
    use 14 digits, so their output looks tidier but does not round-trip.

    ```lua title="examples/02-syntax-types/float_print.lua"
    --8<-- "examples/02-syntax-types/float_print.lua"
    ```

    === "Lua 5.5"
        ```text
        --8<-- "examples/02-syntax-types/float_print.expected"
        ```
    === "Lua 5.4"
        ```text
        --8<-- "examples/02-syntax-types/float_print.5.4.expected"
        ```
    === "LuaJIT 2.1"
        ```text
        --8<-- "examples/02-syntax-types/float_print.jit.expected"
        ```

    If your program's output or tests depend on `print`/`tostring` of floats,
    they can change when you move from 5.4 to 5.5. Use `string.format` when the
    exact text matters.

## Truthiness and `and`/`or`

Only `nil` and `false` are falsy. `0`, `""` and empty tables are truthy, which
surprises C++ programmers. `and` and `or` short-circuit and return **one of their
operands**, which gives Lua its most common idiom: `x = x or default`.

```lua title="examples/02-syntax-types/truthiness.lua"
--8<-- "examples/02-syntax-types/truthiness.lua"
```

```text
--8<-- "examples/02-syntax-types/truthiness.expected"
```

!!! danger "The `false` trap"
    `a and b or c` works like C's `a ? b : c` **only if `b` is truthy**. The same goes for
    `x = x or default`: it replaces a legitimate `false`. Compare with `nil`
    explicitly when `false` is a valid value.

## Strings in a nutshell

Strings are immutable byte sequences. There are three ways to write a literal, and
`#` gives the length in **bytes**. Lessons 6 and 7 go much deeper.

```lua title="examples/02-syntax-types/strings_basic.lua"
--8<-- "examples/02-syntax-types/strings_basic.lua"
```

```text
--8<-- "examples/02-syntax-types/strings_basic.expected"
```

The `\u{XXXX}` escape (UTF-8 encoding of a code point) is standard from Lua 5.3
and is also supported by LuaJIT 2.1, as this test shows.

## The `local` habit

Any name you assign without `local` becomes a **global**, which is really a field
in the environment table `_G`. Globals are slower (a table lookup instead of a VM
register), visible to every module, and a misspelled name just reads `nil`
instead of failing to compile:

```lua title="examples/02-syntax-types/locals.lua"
--8<-- "examples/02-syntax-types/locals.lua"
```

```text
--8<-- "examples/02-syntax-types/locals.expected"
```

The rule for this course: **every variable is `local` unless you have a reason.**
Locals are lexically scoped to the enclosing block (`do ... end`, a function body,
a loop body, or the whole file).

### Constant locals (Lua 5.4+)

Lua 5.4 added attributes on locals. `<const>` makes a local read-only, checked at
compile time (`<close>` is covered in Lesson 13):

```lua title="examples/02-syntax-types/const_local.lua"
--8<-- "examples/02-syntax-types/const_local.lua"
```

```text
--8<-- "examples/02-syntax-types/const_local.expected"
```

LuaJIT does not support attributes; the `<` is a syntax error there. Recent
LuaJIT 2.1 builds (July 2026 on) have their own spelling, `const LIMIT = 10`
([details](../version-differences.md#luajit-21-syntax-backports)).

## Lua 5.5: `global` declarations

Lua 5.5's headline language feature finally addresses the typo problem. You can
**declare** globals, and once a chunk declares any global, every other free name
in its scope must be declared too, or the code **does not compile**.

The rules, from the 5.5 reference manual §3.3.7:

- Every chunk starts with an implicit `global *` ("all free names are globals"),
  which is why old code keeps working.
- Any explicit `global` declaration voids that implicit `global *` for the rest of
  its scope. From then on, only declared names may be used.
- `global<const> *` declares every undeclared name a **read-only** global.
- `global x = value` raises a run-time error if `x` already has a non-nil value.
- `global function f() ... end` declares and defines a global function.

```lua title="examples/02-syntax-types/global_decl.lua"
--8<-- "examples/02-syntax-types/global_decl.lua"
```

```text
--8<-- "examples/02-syntax-types/global_decl.expected"
```

!!! warning "Surprise: one `global function` changes the whole file"
    Because *any* explicit declaration voids the implicit `global *`, adding a
    single `global function helper() ... end` near the top of a file makes every
    later use of `print`, `string`, `ipairs` and so on a compile error
    (`variable 'print' not declared`). Either declare what you use
    (`global print, string, ipairs`) or start the file with `global *` /
    `global<const> *`.

!!! info "Version difference: is `global` a keyword?"
    The manual says `global` is reserved in 5.5, but the default build defines
    `LUA_COMPAT_GLOBAL`, which keeps it a **contextual** keyword. With the stock
    5.5.1 build, old code using `global` as a variable name still compiles:

    ```lua title="examples/02-syntax-types/keyword_global.lua"
    --8<-- "examples/02-syntax-types/keyword_global.lua"
    ```
    ```text
    --8<-- "examples/02-syntax-types/keyword_global.expected"
    ```

    The same output appears on 5.4 and LuaJIT. Do not rely on it: the manual
    says compatibility options will be removed in the future.

!!! note "For C++/Rust developers"
    `global<const> *` at the top of a file gives you something close to Rust's
    "everything must be declared" discipline. The check is purely syntactic
    though: code can still write any global through `_ENV.name` or `_G.name`, and
    functions you call can change globals behind your back.

## Hands-on exercises

??? example "Exercise 1: truthiness table"
    Print each of `nil, false, 0, "", "false", {}` with a label saying whether it is
    truthy or falsy. Careful: how do you iterate over a list that contains `nil`?

    ??? success "Solution"
        ```lua
        --8<-- "examples/02-syntax-types/ex1_truthy.lua"
        ```
        ```text
        --8<-- "examples/02-syntax-types/ex1_truthy.expected"
        ```

??? example "Exercise 2: portable `numkind`"
    Write `numkind(x)` that returns `"integer"` or `"float"` on Lua 5.4/5.5 and
    still does something sensible on LuaJIT, where `math.type` does not exist.

    ??? success "Solution"
        ```lua
        --8<-- "examples/02-syntax-types/ex2_numkind.lua"
        ```
        === "Lua 5.5 / 5.4"
            ```text
            --8<-- "examples/02-syntax-types/ex2_numkind.expected"
            ```
        === "LuaJIT 2.1"
            ```text
            --8<-- "examples/02-syntax-types/ex2_numkind.jit.expected"
            ```
        Feature detection (`if math.type then`) is the idiomatic way to write
        code that runs on several Lua versions.

??? example "Exercise 3: catch a typo at compile time (Lua 5.5)"
    A function averaging a list returns `totl / #xs`. Add global declarations so
    that Lua 5.5 refuses to compile it, then show the fixed version running.

    ??? success "Solution"
        ```lua
        --8<-- "examples/02-syntax-types/ex3_typo.lua"
        ```
        ```text
        --8<-- "examples/02-syntax-types/ex3_typo.expected"
        ```

??? example "Exercise 4: defaults that respect `false`"
    Write `opt(value, default)` that returns `default` only when `value` is `nil`.
    Show the difference from `value or default`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/02-syntax-types/ex4_defaults.lua"
        ```
        ```text
        --8<-- "examples/02-syntax-types/ex4_defaults.expected"
        ```

## Quiz

??? question "Q1. What do `7 // 2`, `-7 // 2` and `7 / 2` evaluate to in Lua 5.4?"
    `3`, `-4` (floor division) and `3.5` (`/` always produces a float).

??? question "Q2. Is `0` truthy or falsy? What about `\"\"`?"
    Both are **truthy**. Only `nil` and `false` are falsy.

??? question "Q3. Why does `local v = opts.verbose or true` have a bug?"
    If `opts.verbose` is `false`, `false or true` evaluates to `true`, so the user
    can never turn the option off. Compare with `nil` instead.

??? question "Q4. In Lua 5.5, a file starts with `global function main() ... end` and later calls `print`. What happens?"
    It fails to compile with `variable 'print' not declared`: the explicit
    declaration voids the implicit `global *`. Add `global print` (or
    `global *`) first.

??? question "Q5. `print(0.1 + 0.2)` prints different text on Lua 5.4 and Lua 5.5. Why?"
    Lua 5.4 prints floats with `%.14g` (`0.3`). Lua 5.5 reprints with 17
    significant digits whenever 14 would not round-trip, so it prints
    `0.30000000000000004`.
