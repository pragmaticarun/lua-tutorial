# 19. The LuaJIT FFI

--8<-- "includes/badges/19-ffi.md"

!!! abstract "What you will be able to do after this lesson"
    - Declare C functions and types with `ffi.cdef` and call libc directly.
    - Load your own shared library with `ffi.load` and manage its objects with `ffi.gc`.
    - Use C structs, arrays, pointers, 64-bit integers and metatypes from Lua.
    - Pass Lua functions to C as callbacks, and know what they cost.
    - Know, from measurements, when the FFI is faster than plain Lua and when it is slower.

## Intuition: C declarations are the binding

With the classic Lua C API (Lessons 20–21) you write C glue for every function
you expose. LuaJIT's FFI removes the glue: you paste C declarations into
`ffi.cdef`, and LuaJIT's built-in C parser learns the types and calling
conventions. Calls compiled by the JIT become direct machine-level C calls, and
`cdata` objects (C values living in LuaJIT's heap) are accessed with the same
loads and stores a C compiler would emit.

!!! note "For C++/Rust developers"
    Think `extern "C"` declarations plus `dlopen`/`dlsym`, done at run time, with
    **no safety net**: there is no borrow checker and no bounds checking. An
    out-of-range index or a dangling pointer is undefined behaviour exactly as in C,
    and crashes the whole process. The FFI is LuaJIT-only; PUC Lua 5.4/5.5 have no
    FFI (the third-party `cffi-lua` module offers a compatible subset).

## Calling the C library

```lua title="examples/19-ffi/ffi_libc.lua"
--8<-- "examples/19-ffi/ffi_libc.lua"
```

```text
--8<-- "examples/19-ffi/ffi_libc.expected"
```

- `ffi.C` is the default namespace: the symbols of the C library and of the
  `luajit` executable itself.
- Integer return types wider than 32 bits (`size_t`, `long`) come back as boxed
  64-bit cdata (`5ULL`, `31LL`); use `tonumber` to convert. `int` and `double` come
  back as plain Lua numbers.
- Lua strings are passed as `const char *` automatically (read-only!). For an
  output buffer allocate one with `ffi.new` and copy it out with `ffi.string`.
- Variadic functions work, but arguments get C default promotions: pass integers
  as `ffi.new("int", n)` (a plain Lua number is passed as a `double`).

## Structs, arrays, pointers and metatypes

```lua title="examples/19-ffi/ffi_structs.lua"
--8<-- "examples/19-ffi/ffi_structs.lua"
```

```text
--8<-- "examples/19-ffi/ffi_structs.expected"
```

- Layout, padding and alignment follow the platform C ABI (`sizeof(rect_t)` is 10 here).
- Arrays are **0-based**, fixed-size, and unchecked.
- Assignments convert with C semantics: storing 70000 in a `uint16_t` wraps.
- `ffi.metatype` gives a C type a metatable once and for all: methods, operators
  and `__gc`. It is the FFI's version of a class.
- `LL`/`ULL` literals create 64-bit integer cdata: exact where doubles are not.

## Your own shared library

A plain C library with no Lua headers at all:

```c title="examples/19-ffi/media.c"
--8<-- "examples/19-ffi/media.c"
```

The test runner builds it once as `build/libmedia.so`
(`gcc -O2 -shared -fPIC -o build/libmedia.so media.c`). In Lua:

```lua title="examples/19-ffi/ffi_custom.lua"
--8<-- "examples/19-ffi/ffi_custom.lua"
```

```text
--8<-- "examples/19-ffi/ffi_custom.expected"
```

!!! warning "`ffi.gc` is a safety net, not RAII"
    The finalizer runs when the collector notices the cdata is unreachable, which
    for a small pointer may be much later than you would like (the collector cannot
    see the 76 KB the C side allocated). For big buffers, free explicitly with
    `lib.frame_free(ffi.gc(f, nil))`, as at the end of the example.

## Callbacks

```lua title="examples/19-ffi/ffi_callbacks.lua"
--8<-- "examples/19-ffi/ffi_callbacks.lua"
```

```text
--8<-- "examples/19-ffi/ffi_callbacks.expected"
```

Converting a Lua function to a C function pointer creates a **callback**, a small
machine-code trampoline. There are a limited number of slots (free them with
`cb:free()`), each call from C into Lua is slow (it cannot be JIT-compiled across
the boundary), and a callback must not be called after `free`. Prefer C APIs that
fill buffers (like `frame_histogram` in Exercise 4) over per-element callbacks.

## Measured: FFI vs plain Lua

```lua title="examples/19-ffi/ffi_perf.lua"
--8<-- "examples/19-ffi/ffi_perf.lua"
```

```text
--8<-- "examples/19-ffi/ffi_perf.expected"
```

--8<-- "includes/bench/19-ffi.md"

What the numbers say:

- **With the JIT**, FFI data structures win when they replace tables of tables
  or byte tables: an array of C structs is about 20× faster than a table of
  `{x, y}` tables (no per-element allocation, no hash lookups), and byte buffers
  are 3× faster than tables of bytes. A flat Lua array of numbers is already
  fast; `double[]` only saves memory there.
- **Without the JIT** (`-joff`, or any code whose trace aborts), every FFI access
  goes through slow generic paths: the same FFI code is 15–90× *slower* than in
  JIT mode and slower than plain Lua tables. The FFI is designed for compiled
  code: combine it with Lesson 18's rules.
- Calling a C function such as `sqrt` through the FFI is no slower than the
  built-in `math.sqrt` in compiled code (faster in this run), but 8× slower than
  it in the interpreter.

## Hands-on exercises

??? example "Exercise 1: errno and strerror"
    Wrap `fopen` so that failure returns `nil, message` like `io.open`, using `ffi.errno()` and `strerror`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/19-ffi/ex1_errno.lua"
        ```
        ```text
        --8<-- "examples/19-ffi/ex1_errno.expected"
        ```

??? example "Exercise 2: a vec3 metatype"
    Give a `struct {{ float x, y, z; }}` operators (`+`, `*`, `#`, `==`), `tostring` and methods.

    ??? success "Solution"
        ```lua
        --8<-- "examples/19-ffi/ex2_vec3.lua"
        ```
        ```text
        --8<-- "examples/19-ffi/ex2_vec3.expected"
        ```

??? example "Exercise 3: a ring buffer of samples"
    Build a fixed-capacity ring buffer of `int16_t` samples that overwrites the oldest sample when full.

    ??? success "Solution"
        ```lua
        --8<-- "examples/19-ffi/ex3_ring.lua"
        ```
        ```text
        --8<-- "examples/19-ffi/ex3_ring.expected"
        ```

??? example "Exercise 4: pass arrays to C"
    Call `frame_histogram` with a `uint32_t[256]` array and check the result against a histogram computed in Lua.

    ??? success "Solution"
        ```lua
        --8<-- "examples/19-ffi/ex4_histogram.lua"
        ```
        ```text
        --8<-- "examples/19-ffi/ex4_histogram.expected"
        ```

## Quiz

??? question "Q1. What does `ffi.C.strlen(\"abc\")` return, and how do you get a Lua number?"
    A `uint64_t` cdata (`3ULL`), because `size_t` is 64 bits; `tonumber()` converts it.

??? question "Q2. Is `local a = ffi.new(\"int[4]\"); a[4] = 1` an error?"
    No error is raised: it writes past the end of the array, which is undefined
    behaviour as in C. FFI arrays are 0-based and unchecked.

??? question "Q3. How do you make sure a C object returned by `frame_new` is freed?"
    `ffi.gc(ptr, lib.frame_free)` attaches a finalizer; for prompt release, call the
    free function yourself and disarm the finalizer with `ffi.gc(ptr, nil)`.

??? question "Q4. Why can FFI code be slower than plain Lua?"
    In the interpreter (JIT off, or an aborted trace) cdata accesses and FFI calls
    take generic slow paths; the FFI is only fast in compiled traces.

??? question "Q5. Can you use `ffi` in Lua 5.4?"
    No, it is part of LuaJIT. Lua 5.4/5.5 need C modules (Lesson 21) or a
    third-party library such as `cffi-lua`.
