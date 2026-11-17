??? success "Tested with Lua 5.5.1 · Lua 5.4.9 · LuaJIT 2.1.1794386141"
    - Lua 5.5.1: 7 examples passed
    - Lua 5.4.9: 7 examples passed
    - LuaJIT 2.1.1794386141: 6 examples passed (1 written for other versions only)

    Every code block on this page is a real file under `examples/21-capi-modules/`, run on each
    interpreter by `tests/run_all.sh` and compared with its `.expected` output.
    C, C++ and Rust examples are compiled against each interpreter's own headers
    and static library, then run the same way.
