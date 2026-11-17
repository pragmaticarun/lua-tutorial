# Glossary

**Border**
:   An index `n` of a table where `t[n] ~= nil` and `t[n+1] == nil` (or `0` when `t[1]` is `nil`). `#t` returns some border. See [Lesson 4](part1/04-tables-1.md).

**Chunk**
:   A unit of compilation: a file, a string passed to `load`, or a line typed in the REPL. A chunk is compiled into an anonymous variadic function.

**Closure**
:   A function value together with the upvalues it captured. Every `function ... end` expression creates a new closure. See [Lesson 9](part1/09-closures.md).

**Coroutine**
:   A "thread" value in Lua: an independent call stack you resume and yield explicitly. Cooperative, not an OS thread. Planned for Lesson 14.

**Environment (`_ENV`)**
:   The table in which free names (globals) are looked up. `_G` is the default global table. Since Lua 5.2 every chunk has an `_ENV` upvalue; Lua 5.1 and LuaJIT use `setfenv` instead.

**FFI**
:   LuaJIT's Foreign Function Interface: declare C types and functions in Lua and call them directly, without writing C bindings. Planned for Lesson 19.

**Frontier pattern**
:   `%f[set]`: matches the empty position where the previous character is not in `set` and the next is. Used for word boundaries. See [Lesson 7](part1/07-patterns.md).

**Generic `for`**
:   `for vars in explist do ... end`: repeatedly calls an iterator function until its first result is `nil`. See [Lesson 3](part1/03-control-flow.md).

**Global declaration**
:   Lua 5.5's `global name`, `global<const> *` or `global function f`. Once a scope declares any global, undeclared free names become compile errors. See [Lesson 2](part1/02-syntax-types.md).

**Integer subtype**
:   Since Lua 5.3, numbers are either 64-bit integers or double floats. `math.type` tells them apart. LuaJIT has only doubles.

**Interning**
:   Keeping a single copy of each short string, so string equality is a pointer comparison.

**Metatable / metamethod**
:   A table attached to a value that customises its behaviour (`__index`, `__add`, `__call`, …). Planned for Lesson 10.

**Multiple results**
:   A function can return several values. Only the last expression in a list expands to all of them; others are truncated to one. See [Lesson 8](part1/08-functions.md).

**Pattern**
:   Lua's lightweight alternative to regular expressions, used by `find`, `match`, `gmatch` and `gsub`. See [Lesson 7](part1/07-patterns.md).

**Proper tail call**
:   A call in the form `return f(args)`, which reuses the caller's stack frame, so tail recursion never overflows. See [Lesson 8](part1/08-functions.md).

**PUC-Rio Lua**
:   The reference implementation from the Pontifical Catholic University of Rio de Janeiro, where Lua was created. Lua 5.4 and 5.5 in this course.

**REPL**
:   Read-eval-print loop: running `lua` without a script. Lua 5.3+ prints expression values; LuaJIT needs `=expr`.

**Sequence**
:   A table whose positive integer keys are exactly `1..n` for some `n`. `#`, `ipairs` and the `table` library are defined for sequences.

**Table**
:   Lua's only data structure: an associative array with an array part and a hash part. See [Lessons 4](part1/04-tables-1.md) and [5](part1/05-tables-2.md).

**To-be-closed variable**
:   A `local x <close>` (Lua 5.4+) whose `__close` metamethod runs when it goes out of scope, like RAII or Rust's `Drop`. Planned for Lesson 13.

**Trace (LuaJIT)**
:   A linear sequence of operations recorded from a hot loop or function and compiled to machine code. Some operations (for example closure creation, bytecode `FNEW`) are "NYI" and abort trace recording.

**Upvalue**
:   A local variable of an enclosing function captured by a closure, shared by reference. See [Lesson 9](part1/09-closures.md).

**Userdata**
:   A block of memory owned by C code and exposed to Lua, with an optional metatable. `io.stdout` is one. Planned for Lessons 20–21.

**Vararg (`...`)**
:   The extra arguments of a variadic function. Lua 5.5 can name them as a table: `function f(...args)`. See [Lesson 8](part1/08-functions.md).
