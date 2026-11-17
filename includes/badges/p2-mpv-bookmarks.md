??? success "Tested with Lua 5.5.1 · Lua 5.4.9 · LuaJIT 2.1.1794386141 · mpv 0.42.0"
    - Lua 5.5.1: 5 tests passed
    - Lua 5.4.9: 5 tests passed
    - LuaJIT 2.1.1794386141: 5 tests passed
    - mpv 0.42.0 (embeds Lua 5.1 / LuaJIT 2.1.1744318430): 2 host tests passed

    Every code block on this page is a real file under `projects/p2-mpv-bookmarks/`. `tests/run_all.sh`
    runs its steps and exercises on each interpreter, and its `*.test.sh` drivers
    (builds, command-line runs, real host runs) once per interpreter or inside the
    host, locally and in CI, comparing every output with its `.expected` file.
