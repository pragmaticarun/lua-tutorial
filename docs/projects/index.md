# Projects

Six end-to-end projects that combine the lessons. Each is a **guided build**:
the design first, then incremental steps whose code is the real, complete
project under [`projects/`](https://github.com/pragmaticarun/lua-tutorial/tree/main/projects)
in the repository, then extension exercises with hidden solutions and a short quiz.
Every step, exercise and test runs in CI on Lua 5.5.1, Lua 5.4.9 and LuaJIT 2.1
and, where a host is involved, inside the real host; the outputs on these pages
are the expected outputs those runs are compared against.

| # | Project | What you build | Runs on / tested in | Uses lessons |
|---|---|---|---|---|
| 1 | [CLI log analyzer](p1-log-analyzer.md) | `logan`: argument parsing, Lua-pattern parsing of access and app logs, text/JSON reports; a LuaRocks rock with busted specs and luacheck | Lua 5.5, 5.4, LuaJIT; LuaRocks 3.13, busted 2.3, luacheck 1.2 | 7, 9, 12, 13, 28 |
| 2 | [mpv bookmark manager](p2-mpv-bookmarks.md) | Key-bound bookmarks per media file, OSD list, jump next/previous, export as chapters | store logic on all three; plugin in mpv 0.42 (LuaJIT) with a scripted driver | 4–5, 12, 14, 27 |
| 3 | [Neovim notes and task picker](p3-notes-nvim.md) | `:Notes`, `:NoteAdd`, `:Tasks` with a floating picker, highlights, tag completion and `:checkhealth` | task model on all three; plugin headless in Neovim 0.12.6 | 7, 12, 23 |
| 4 | [LÖVE arcade game](p4-love-arcade.md) | Brick Rush: states, levels, combo scoring, pause, high scores; deterministic autoplay | game logic on all three; a full autoplayed game in LÖVE 11.5 with pixel checks | 9–12, 24 |
| 5 | [C++ media pipeline](p5-cpp-pipeline.md) | A CMake C++17 host running Lua filter scripts with sandboxing, memory/instruction/time limits and rollback | built and run against Lua 5.5, 5.4 and LuaJIT | 13, 18, 20, 21 |
| 6 | [Bonus: Rust host](p6-rust-pipeline.md) | The same scripting layer with `mlua` 0.12, byte-identical output, compared line by line | built with mlua for Lua 5.5, 5.4 and LuaJIT | 22 |

!!! tip "How to work through a project"
    Read the design section, then rebuild each step yourself before opening the
    next code block, and run the tests in the project directory, for example
    `cd projects/p1-logan && busted` or `tests/run_all.sh p4-love` from the
    repository root. The exercises extend the finished project. Solutions that contain
    code are tested files, except the LÖVE sound exercise (CI has no audio
    device), which the page marks as untested.
