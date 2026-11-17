# Part 4: Lua in the Real World

Lua is rarely a program's main language; it is the language *inside* programs.
This part uses six real hosts, each with the Lua it actually embeds, and tests
every example against the **real program**, locally and in CI: no mocked APIs,
no pasted output.

| # | Lesson | Host tested (pinned) | Lua inside the host |
|---|---|---|---|
| 23 | [Neovim](23-neovim.md): config in Lua, `vim.api`, keymaps, autocommands, a plugin | Neovim 0.12.6, official build | LuaJIT 2.1.1774638290 |
| 24 | [LÖVE](24-love.md): game loop, input, drawing, collisions | LÖVE 11.5 AppImage, under `xvfb-run` | LuaJIT 2.1.1700008891 |
| 25 | [Redis scripting](25-redis.md): `EVAL`/`EVALSHA`, atomic rate limiter, Functions | Redis 8.10.3, built from source | PUC Lua 5.1 |
| 26 | [OpenResty](26-openresty.md): phases, `ngx.*`, cosockets, an API gateway | OpenResty 1.31.8.1, built from source | OpenResty LuaJIT 2.1-20261023 (reports `2.1.ROLLING`) |
| 27 | [mpv scripting](27-mpv.md): events, properties, key bindings, OSD | mpv 0.42.0, built from source with LuaJIT | LuaJIT 2.1.1744318430 |
| 28 | [Tooling](28-tooling.md): LuaRocks, busted, luacheck, StyLua, GitHub Actions | LuaRocks 3.13.0, busted 2.3.0, luacheck 1.2.0, StyLua 2.6.0 | busted on Lua 5.5, 5.4 and LuaJIT |

Note the pattern: **five of the six hosts run Lua 5.1 semantics** (LuaJIT or
PUC 5.1). Code written for these hosts cannot use integers, `//`, the 5.3
bitwise operators, `<const>`/`<close>` or 5.5's `global` declarations. Lesson
24's logic modules and Lesson 28's library are additionally run on Lua 5.5 and
5.4 to show portable code is possible.

## Installing the hosts

`scripts/install-hosts.sh` installs the exact versions above under `/opt/hosts`
(checksums verified) and puts small wrappers in `/usr/local/bin`. CI runs the same
script and caches the result.

```bash
scripts/install-interpreters.sh   # Lua 5.5, 5.4, LuaJIT (Part 1; LuaRocks builds against them)
sudo apt install xvfb xauth libgl1 libegl1 libgl1-mesa-dri libssl-dev unzip
scripts/install-hosts.sh          # or: scripts/install-hosts.sh nvim redis
tests/run_all.sh 23-neovim        # run one lesson's tests
```

| Host | How it is installed | Why |
|---|---|---|
| Neovim | official release tarball | the build users actually download |
| Redis | `make -C src` from the release tarball | core server only; Redis 8's top-level build also compiles bundled modules |
| OpenResty | `./configure` with PCRE2 and zlib sources, system OpenSSL | the official way to build it; no distro package needed |
| mpv | meson build against a locked conda-forge environment | conda-forge's mpv package has no Lua; distro packages differ between machines |
| LÖVE | official AppImage, extracted | no FUSE needed; runs headless under `xvfb-run` with Mesa |
| LuaRocks, busted, luacheck | LuaRocks from source, rocks from luarocks.org | one rocks tree per interpreter |
| StyLua | official release binary | single static binary |

!!! info "What runs where"
    Every host test ran both on the author's machine (Debian 13) and on GitHub's
    `ubuntu-latest` runners, with identical expected output. Nothing on these pages
    is "should work": if a host cannot run in an environment, the test runner
    reports it as skipped and the page's badge says so.
