# 11. Object-Oriented Programming with Prototypes

--8<-- "includes/badges/11-oop.md"

!!! abstract "What you will be able to do after this lesson"
    - Write classes with constructors and methods using `__index` and the `:` syntax.
    - Build inheritance chains, override methods and call the "super" implementation.
    - Avoid the classic trap: metamethods are not inherited through `__index`.
    - Compose behaviour with mixins, and get true privacy with closures.

## Intuition: objects are tables, classes are fallbacks

Lua has no `class` keyword. It has two things that are enough:

1. **Tables** that hold an object's own state (`self.title`).
2. **`__index`** (Lesson 10): when a key is missing from the object, look it up
   in another table, the *class*. If it is missing there too, the class's own
   metatable can point to a *parent class*, and so on.

That is prototype-based OOP, as in JavaScript or Self: method lookup walks a
chain of tables at run time. The `:` syntax supplies `self` so it reads like the
OOP you know.

!!! note "For C++/Rust developers"
    Think of the class table as a vtable plus static members, and the instance
    as a struct holding a pointer to it. Lookup is dynamic, so every method is
    effectively `virtual`, there is no `final`, and you can add methods to a
    class (or to a single object) at run time. There are no access modifiers;
    privacy comes from closures or convention (`_private` names).

## A class in ten lines

```lua title="examples/11-oop/class_basic.lua"
--8<-- "examples/11-oop/class_basic.lua"
```

```text
--8<-- "examples/11-oop/class_basic.expected"
```

`function Track:duration()` is sugar for `function Track.duration(self)`, and
`t:duration()` is sugar for `t.duration(t)`. The methods exist only once, in
`Track`; each instance only holds its own fields.

### The colon is not optional

```lua title="examples/11-oop/colon.lua"
--8<-- "examples/11-oop/colon.lua"
```

=== "Lua 5.5 / 5.4"
    ```text
    --8<-- "examples/11-oop/colon.expected"
    ```
=== "LuaJIT 2.1"
    ```text
    --8<-- "examples/11-oop/colon.jit.expected"
    ```

`c.inc(5)` passes `5` as `self`. When you see "attempt to index a number value
(local 'self')", look for a `.` that should be a `:`.

## Inheritance

A subclass is a class whose metatable's `__index` is the base class. Overriding
is just defining the same name in the subclass; calling the base version is an
explicit call with `self`:

```lua title="examples/11-oop/inheritance.lua"
--8<-- "examples/11-oop/inheritance.lua"
```

```text
--8<-- "examples/11-oop/inheritance.expected"
```

Lookup for `s:describe()` on a `VideoStream` goes: the instance → `VideoStream`
(found). For `s.codec`: the instance (found). For a method only `Stream` has:
instance → `VideoStream` → `Stream`.

## The trap: metamethods are not inherited

When Lua needs a metamethod such as `__tostring`, it reads it from the
metatable **raw**, without following `__index`. A subclass therefore does not
get its parent's operators or `__tostring`:

```lua title="examples/11-oop/metamethods_not_inherited.lua"
--8<-- "examples/11-oop/metamethods_not_inherited.lua"
```

```text
--8<-- "examples/11-oop/metamethods_not_inherited.expected"
```

Note `rawget(Derived, k)`: a plain `Derived[k]` would *find* `Base.__tostring`
through `__index`, which is exactly why the bug is so confusing.

## A reusable `class()` helper

Most projects wrap the pattern in a small helper that also copies metamethods
and calls an `init` method. Libraries such as *middleclass* and *classic* are
bigger versions of this:

```lua title="examples/11-oop/class_helper.lua"
--8<-- "examples/11-oop/class_helper.lua"
```

```text
--8<-- "examples/11-oop/class_helper.expected"
```

## Mixins

Instead of deep hierarchies, copy reusable behaviour into a class. This is
composition, like Rust traits with default methods (minus the type checking):

```lua title="examples/11-oop/mixins.lua"
--8<-- "examples/11-oop/mixins.lua"
```

```text
--8<-- "examples/11-oop/mixins.expected"
```

## Privacy with closures

If state must be truly private, keep it in upvalues (Lesson 9) instead of fields.
Methods are closures, so they are called with `.` and no `self`:

```lua title="examples/11-oop/privacy.lua"
--8<-- "examples/11-oop/privacy.lua"
```

```text
--8<-- "examples/11-oop/privacy.expected"
```

| | Metatable classes | Closure objects |
|---|---|---|
| Memory per object | Fields only; methods shared | One closure per method per object |
| Privacy | Convention (`_name`) | Real |
| Inheritance / mixins | Natural | Manual (wrap or copy) |
| Call syntax | `obj:method()` | `obj.method()` |
| Speed | Method lookup via `__index` | Upvalue access, slightly faster calls |

Use metatable classes by default, and closure objects for small numbers of
objects that guard invariants (connections, players, configuration).

!!! info "Version notes"
    Everything in this lesson runs unchanged on Lua 5.5, 5.4 and LuaJIT. The
    differences show up in the metamethods you give a class: LuaJIT ignores
    `__len` on tables and uses the 5.1 `__eq` rule, and Lua 5.5 needs an explicit
    `__le` (Lesson 10).

## Hands-on exercises

??? example "Exercise 1: Stack"
    Write a `Stack` class with chainable `push`, `pop` (returning `nil, "empty"`
    when empty), `peek` and `size`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/11-oop/ex1_stack.lua"
        ```
        ```text
        --8<-- "examples/11-oop/ex1_stack.expected"
        ```
        `__len` would let you write `#s`, but only on 5.2+; `size()` works everywhere.

??? example "Exercise 2: shapes"
    Create a `Shape` base class with an abstract `area()` and a `describe()` that
    uses it, plus `Square` and `Triangle` subclasses.

    ??? success "Solution"
        ```lua
        --8<-- "examples/11-oop/ex2_shapes.lua"
        ```
        ```text
        --8<-- "examples/11-oop/ex2_shapes.expected"
        ```

??? example "Exercise 3: a Comparable mixin"
    Write a mixin that derives `==`, `<` and `<=` from a single `compare` method,
    and use it for semantic version numbers, including `table.sort`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/11-oop/ex3_comparable.lua"
        ```
        ```text
        --8<-- "examples/11-oop/ex3_comparable.expected"
        ```

??? example "Exercise 4: private volume control"
    Build a closure-based volume object whose level is clamped to 0–100 and
    cannot be read or written directly.

    ??? success "Solution"
        ```lua
        --8<-- "examples/11-oop/ex4_private.lua"
        ```
        ```text
        --8<-- "examples/11-oop/ex4_private.expected"
        ```

??? example "Exercise 5: is_instance"
    Write `is_instance(obj, cls)` that works for any depth of inheritance.

    ??? success "Solution"
        ```lua
        --8<-- "examples/11-oop/ex5_isinstance.lua"
        ```
        ```text
        --8<-- "examples/11-oop/ex5_isinstance.expected"
        ```

## Quiz

??? question "Q1. What does `function Track:play(x)` expand to?"
    `function Track.play(self, x)`, that is, `Track.play = function(self, x) ... end`.

??? question "Q2. Why does `Track.__index = Track` appear in almost every class?"
    Instances use `Track` as their metatable; setting its `__index` to itself makes
    missing keys on an instance (the methods) resolve in `Track`.

??? question "Q3. A subclass instance prints as `table: 0x...` although the base class defines `__tostring`. Why?"
    Metamethods are read raw from the instance's metatable (the subclass) and are
    not looked up through `__index`. Copy them into the subclass.

??? question "Q4. How do you call the parent's version of an overridden method?"
    Call it explicitly with `self`: `Base.method(self, ...)`.

??? question "Q5. When would you prefer closure-based objects?"
    When you need real privacy or strong invariants and have relatively few
    objects; they cost one closure per method per instance.
