# Part 2: The Lua Way

How idiomatic Lua is built: metatables turn tables into objects, modules and
error handling structure programs, coroutines replace callbacks, and knowing the
standard library, the collector and the cost model lets you write fast,
leak-free code. Every lesson is tested on Lua 5.5, Lua 5.4 and LuaJIT 2.1.

| # | Lesson | You will learn |
|---|---|---|
| 10 | [Metatables and Metamethods](10-metatables.md) | `__index`, `__newindex`, arithmetic, `__eq`/`__lt`/`__le`, `__call`, `__tostring`, `__close` |
| 11 | [OOP with Prototypes](11-oop.md) | Classes, `:` syntax, inheritance, mixins, privacy with closures |
| 12 | [Modules and `require`](12-modules.md) | Module patterns, `package.path`, searchers, `package.preload`, avoiding globals |
| 13 | [Error Handling](13-errors.md) | `error` levels, `pcall`, `xpcall` tracebacks, error objects, to-be-closed variables |
| 14 | [Iterators and Coroutines](14-coroutines.md) | Stateless and stateful iterators, generators, producer/consumer, a tiny scheduler |
| 15 | [The Standard Library Tour](15-stdlib.md) | `io`, `os`, `math`, `debug` hooks and introspection |
| 16 | [Garbage Collection](16-gc.md) | Incremental vs generational, tuning, weak tables, ephemerons, finalizers |
| 17 | [Performance](17-performance.md) | A benchmark harness, measured results on all three interpreters, profiling |

!!! tip "Version differences matter more here"
    Part 2 is where Lua 5.4/5.5 and LuaJIT diverge most (`__close`, `__gc` on
    tables, ephemerons, `require` arguments, GC modes). Each lesson shows the output
    of every interpreter in tabs when they differ, and the
    [cheat sheet](../version-differences.md) collects them.
