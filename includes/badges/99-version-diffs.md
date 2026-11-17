??? success "Tested with Lua 5.5.1 · Lua 5.4.9 · LuaJIT 2.1.1794386141 · Neovim 0.12.6"
    - Lua 5.5.1: 4 examples passed (1 written for other versions only)
    - Lua 5.4.9: 4 examples passed (1 written for other versions only)
    - LuaJIT 2.1.1794386141: 5 examples passed
    - Neovim 0.12.6 (embeds Lua 5.1 / LuaJIT 2.1.1774638290): 1 host tests passed

    Every code block on this page is a real file under `examples/99-version-diffs/`, run on each
    interpreter by `tests/run_all.sh` and compared with its `.expected` output.
    Host examples run inside the real program (driven by the `*.test.sh` scripts
    next to them, or `nvim --headless -l`), and their output is compared the same way.
