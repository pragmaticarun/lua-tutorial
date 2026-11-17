??? success "Tested with Lua 5.5.1 · Lua 5.4.9 · LuaJIT 2.1.1794386141"
    - Lua 5.5.1: 4 tests passed
    - Lua 5.4.9: 4 tests passed
    - LuaJIT 2.1.1794386141: 4 tests passed

    Every code block on this page is a real file under `projects/p6-rust-pipeline/`. `tests/run_all.sh`
    runs its steps and exercises on each interpreter, and its `*.test.sh` drivers
    (builds, command-line runs, real host runs) once per interpreter or inside the
    host, locally and in CI, comparing every output with its `.expected` file.
