---
hide:
  - navigation
---

# Learn Lua: From Foundations to Embedding

A hands-on Lua course for developers who already know a systems language. It
starts with the language itself, moves on to "the Lua way" (metatables,
coroutines, modules), then to systems work (LuaJIT, its FFI, the C API, Rust
with `mlua`), and finishes with real hosts: Neovim, LÖVE, Redis, OpenResty and mpv.

!!! success "Every example is tested"
    Every code block in this course is a real `.lua` file in the repository's
    `examples/` directory, executed on **Lua 5.5.1**, **Lua 5.4.9** and
    **LuaJIT 2.1** on every push. The output you see on a page *is* the
    expected-output file the test compares against, so text and code cannot drift
    apart. Each lesson shows which interpreters it passed on.

## How each lesson works

The teaching style is "intuition first":

1. **Intuition**: what problem the feature solves and the mental model to keep.
2. **Worked examples**: small, complete programs with their real output.
3. **For C++/Rust developers**: how the idea maps to what you already know.
4. **Version notes**: honest, tested differences between Lua 5.5, 5.4 and LuaJIT.
5. **Exercises**: 3–5 per lesson, with solutions hidden until you click.
6. **Quiz**: 5 questions with hidden answers.

## Course map

<div class="grid cards" markdown>

-   :material-numeric-1-box: **[Part 1: Foundations](part1/index.md)**

    ---

    Syntax, types, control flow, tables, strings, patterns, functions, closures.

-   :material-numeric-2-box: **[Part 2: The Lua Way](part2/index.md)**

    ---

    Metatables, OOP, modules, error handling, coroutines, the standard library, GC, performance.

-   :material-numeric-3-box: **[Part 3: Systems Lua](part3/index.md)**

    ---

    LuaJIT and its FFI, the C API, writing C modules, embedding with Rust and `mlua`.

-   :material-numeric-4-box: **[Part 4: Lua in the Real World](part4/index.md)**

    ---

    Neovim, LÖVE, Redis, OpenResty, mpv, and the tooling: LuaRocks, busted, luacheck, StyLua.

-   :material-hammer-wrench: **[Projects](projects/index.md)**

    ---

    Six tested guided builds: a log analyzer rock, an mpv bookmark plugin, a Neovim
    plugin, a LÖVE game, a sandboxed C++ media pipeline scripted in Lua, and its Rust twin.

-   :material-compare-horizontal: **[Version Differences](version-differences.md)**

    ---

    A tested cheat sheet of what changes between Lua 5.5, 5.4 and LuaJIT 2.1.

</div>

## Start here

1. Build the three interpreters: [Setup](setup.md).
2. Read [Lesson 1: Why Lua](part1/01-why-lua.md).
3. Keep the [Glossary](glossary.md) and the [Version Differences](version-differences.md) cheat sheet open in a tab.

!!! info "Which Lua should I learn?"
    Learn the language on **Lua 5.5** (the latest release, December 2025, with
    5.5.1 in July 2026), but keep in mind that most embedded Lua in the wild is
    **5.4** or **LuaJIT/5.1**. The course flags every place where that matters.
