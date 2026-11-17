# Glossary

**AABB**
:   Axis-aligned bounding box: a rectangle `{x, y, w, h}` whose sides are parallel to the axes; two overlap when they overlap on both axes. See [Lesson 24](part4/24-love.md).

**Augroup (Neovim)**
:   A named group of autocommands; creating it with `clear = true` deletes its old autocommands, so re-sourcing a config does not duplicate them. See [Lesson 23](part4/23-neovim.md).

**Autocommand (Neovim)**
:   A callback run on an editor event (`BufWritePre`, `FileType`, `User`, ...), created with `nvim_create_autocmd`. See [Lesson 23](part4/23-neovim.md).

**Blacklisting (LuaJIT)**
:   After repeated trace aborts at the same place, LuaJIT stops trying to compile it, so that code always runs in the interpreter. See [Lesson 18](part3/18-luajit.md).

**Border**
:   An index `n` of a table where `t[n] ~= nil` and `t[n+1] == nil` (or `0` when `t[1]` is `nil`). `#t` returns some border. See [Lesson 4](part1/04-tables-1.md).

**cdata**
:   A C value (number, struct, array, pointer) living in LuaJIT's heap, created by the FFI. See [Lesson 19](part3/19-ffi.md).

**Chunk**
:   A unit of compilation: a file, a string passed to `load`, or a line typed in the REPL. A chunk is compiled into an anonymous variadic function.

**Closure**
:   A function value together with the upvalues it captured. Every `function ... end` expression creates a new closure. See [Lesson 9](part1/09-closures.md).

**Coroutine**
:   A "thread" value in Lua: an independent call stack you resume and yield explicitly. Cooperative, not an OS thread. See [Lesson 14](part2/14-coroutines.md).

**Cosocket (OpenResty)**
:   A non-blocking socket (`ngx.socket.tcp`) whose blocking-looking calls yield the request's coroutine to nginx's event loop. See [Lesson 26](part4/26-openresty.md).

**Environment (`_ENV`)**
:   The table in which free names (globals) are looked up. `_G` is the default global table. Since Lua 5.2 every chunk has an `_ENV` upvalue; Lua 5.1 and LuaJIT use `setfenv` instead.

**Ephemeron table**
:   A table with weak keys and strong values in which a value keeps its key alive only if the key is reachable from elsewhere (Lua 5.2+; not LuaJIT). See [Lesson 16](part2/16-gc.md).

**Extmark (Neovim)**
:   A position in a buffer that moves with edits, optionally carrying highlights or virtual text, grouped by namespace. See [Lesson 23](part4/23-neovim.md).

**FFI**
:   LuaJIT's Foreign Function Interface: declare C types and functions in Lua and call them directly, without writing C bindings. See [Lesson 19](part3/19-ffi.md).

**Finalizer**
:   A `__gc` metamethod, called after the collector finds the object unreachable. Works on tables in Lua 5.2+, only on userdata/cdata in LuaJIT. See [Lesson 16](part2/16-gc.md).

**Fixed timestep**
:   Advancing a simulation in equal steps (e.g. 1/60 s) regardless of frame time, accumulating leftover time; makes games deterministic. See [Lesson 24](part4/24-love.md).

**Frontier pattern**
:   `%f[set]`: matches the empty position where the previous character is not in `set` and the next is. Used for word boundaries. See [Lesson 7](part1/07-patterns.md).

**Generational collection**
:   A GC mode (Lua 5.4+) that collects young objects frequently and old ones rarely. The standalone `lua` program uses it by default. See [Lesson 16](part2/16-gc.md).

**Generic `for`**
:   `for vars in explist do ... end`: repeatedly calls an iterator function until its first result is `nil`. See [Lesson 3](part1/03-control-flow.md).

**Global declaration**
:   Lua 5.5's `global name`, `global<const> *` or `global function f`. Once a scope declares any global, undeclared free names become compile errors. See [Lesson 2](part1/02-syntax-types.md).

**Guard**
:   A check in a compiled LuaJIT trace (marked `>` in `-jdump` IR) that leaves the trace when an assumption made during recording no longer holds. See [Lesson 18](part3/18-luajit.md).

**Hook (mpv)**
:   A callback (`mp.add_hook`, e.g. `on_load`, `on_unload`) that pauses the player until it returns, so a script can change a file's options before it opens. See [Lesson 27](part4/27-mpv.md).

**Integer subtype**
:   Since Lua 5.3, numbers are either 64-bit integers or double floats. `math.type` tells them apart. LuaJIT has only doubles.

**Interning**
:   Keeping a single copy of each short string, so string equality is a pointer comparison.

**Light thread (OpenResty)**
:   A coroutine started with `ngx.thread.spawn` that runs concurrently with others inside one request. See [Lesson 26](part4/26-openresty.md).

**Light userdata**
:   A bare C pointer stored as a Lua value: no metatable of its own, no memory management, compared by address. See [Lesson 21](part3/21-capi-modules.md).

**Metatable / metamethod**
:   A table attached to a value that customises its behaviour (`__index`, `__add`, `__call`, …). See [Lesson 10](part2/10-metatables.md).

**mlua**
:   A Rust crate for embedding Lua 5.1–5.5, LuaJIT or Luau and for writing Lua modules in Rust. See [Lesson 22](part3/22-mlua.md).

**Multiple results**
:   A function can return several values. Only the last expression in a list expands to all of them; others are truncated to one. See [Lesson 8](part1/08-functions.md).

**Pattern**
:   Lua's lightweight alternative to regular expressions, used by `find`, `match`, `gmatch` and `gsub`. See [Lesson 7](part1/07-patterns.md).

**Phase (nginx/OpenResty)**
:   A stage of request processing (rewrite, access, content, header/body filter, log); OpenResty runs Lua via `*_by_lua` directives in each. See [Lesson 26](part4/26-openresty.md).

**Proper tail call**
:   A call in the form `return f(args)`, which reuses the caller's stack frame, so tail recursion never overflows. See [Lesson 8](part1/08-functions.md).

**Property (mpv)**
:   A named piece of player state (`pause`, `time-pos`, `track-list`) that scripts can get, set and observe. See [Lesson 27](part4/27-mpv.md).

**Prototype**
:   An object used as the `__index` fallback of other objects; Lua's classes and inheritance are chains of prototypes. See [Lesson 11](part2/11-oop.md).

**PUC-Rio Lua**
:   The reference implementation from the Pontifical Catholic University of Rio de Janeiro, where Lua was created. Lua 5.4 and 5.5 in this course.

**Redis Function**
:   Named Lua code loaded with `FUNCTION LOAD` as part of a library, persisted and replicated, called with `FCALL`/`FCALL_RO`. See [Lesson 25](part4/25-redis.md).

**Registry**
:   A table only C code can reach (`LUA_REGISTRYINDEX`), used for metatables, references (`luaL_ref`) and module-private data. See [Lesson 21](part3/21-capi-modules.md).

**REPL**
:   Read-eval-print loop: running `lua` without a script. Lua 5.3+ prints expression values; LuaJIT needs `=expr`.

**Rockspec**
:   The Lua file describing a LuaRocks package (name, version, source, dependencies, build); a *rock* is the installable package. See [Lesson 28](part4/28-tooling.md).

**Runtimepath (Neovim)**
:   The list of directories Neovim searches for `plugin/`, `lua/`, `ftplugin/`, ...; installing a plugin means adding its directory here. See [Lesson 23](part4/23-neovim.md).

**Script cache (Redis)**
:   Server-side cache of `EVAL` scripts keyed by the SHA1 of their text, called with `EVALSHA`; emptied by restart or `SCRIPT FLUSH`. See [Lesson 25](part4/25-redis.md).

**Searcher**
:   A function in `package.searchers` (`package.loaders` in LuaJIT) that `require` asks to find a module. See [Lesson 12](part2/12-modules.md).

**Sequence**
:   A table whose positive integer keys are exactly `1..n` for some `n`. `#`, `ipairs` and the `table` library are defined for sequences.

**Shared dict (OpenResty)**
:   A `lua_shared_dict` memory zone (`ngx.shared.NAME`) shared by all nginx workers, with atomic `incr` and per-key TTLs. See [Lesson 26](part4/26-openresty.md).

**Side trace**
:   A LuaJIT trace compiled for a frequently taken exit of another trace, for example the other branch of an `if`. See [Lesson 18](part3/18-luajit.md).

**Spy / stub (busted)**
:   A spy wraps a function and records calls; a stub replaces it for one test and can return canned values. See [Lesson 28](part4/28-tooling.md).

**Table**
:   Lua's only data structure: an associative array with an array part and a hash part. See [Lessons 4](part1/04-tables-1.md) and [5](part1/05-tables-2.md).

**To-be-closed variable**
:   A `local x <close>` (Lua 5.4+) whose `__close` metamethod runs when it goes out of scope, like RAII or Rust's `Drop`. See [Lessons 10](part2/10-metatables.md) and [13](part2/13-errors.md).

**Token bucket**
:   A rate limiter holding up to N tokens that refill at a fixed rate; each request takes one, so short bursts pass while the average rate is capped. See [Lesson 25](part4/25-redis.md).

**Trace (LuaJIT)**
:   A linear sequence of operations recorded from a hot loop or function and compiled to machine code. Some operations (for example closure creation, bytecode `FNEW`) are "NYI" and abort trace recording. See [Lessons 17](part2/17-performance.md) and [18](part3/18-luajit.md).

**Upvalue**
:   A local variable of an enclosing function captured by a closure, shared by reference. See [Lesson 9](part1/09-closures.md).

**Userdata**
:   C data as a Lua value. A full userdata is a block of memory allocated and collected by Lua, with an optional metatable (`io.stdout` is one); a light userdata is a bare pointer. See [Lesson 21](part3/21-capi-modules.md).

**Vararg (`...`)**
:   The extra arguments of a variadic function. Lua 5.5 can name them as a table: `function f(...args)`. See [Lesson 8](part1/08-functions.md).

**Virtual stack**
:   The array of Lua values through which C code and a `lua_State` exchange arguments and results, addressed by positive or negative indices. See [Lesson 20](part3/20-capi-embed.md).

**Weak table**
:   A table whose `__mode` makes its keys (`"k"`), values (`"v"`) or both weak references that do not keep objects alive. See [Lesson 16](part2/16-gc.md).
