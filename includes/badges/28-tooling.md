??? success "Tested with busted 2.3.0 · LuaRocks 3.13.0 · luacheck 1.2.0 · StyLua 2.6.0"
    - busted 2.3.0 (runs on Lua 5.5, Lua 5.4 and LuaJIT, one rocks tree each): 2 host tests passed
    - LuaRocks 3.13.0 (configured for Lua 5.4): 2 host tests passed
    - luacheck 1.2.0 (runs on PUC-Rio Lua 5.4): 2 host tests passed
    - StyLua 2.6.0 (a Rust binary; syntaxes Lua 5.1-5.4, LuaJIT, Luau, CfxLua): 2 host tests passed

    Every code block on this page is a real file under `examples/28-tooling/`, run inside
    the real host by `tests/run_all.sh` (locally and in CI) and compared with its
    `.expected` output.
