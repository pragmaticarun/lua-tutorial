# Setup: Lua 5.5, Lua 5.4 and LuaJIT on Ubuntu

This course uses three interpreters side by side, installed under `/opt` and
exposed as `lua5.5`, `lua5.4` and `luajit`:

| Command | Version used for the tests | Source |
|---|---|---|
| `lua5.5` | Lua 5.5.1 (2026-07-24) | <https://www.lua.org/ftp/> |
| `lua5.4` | Lua 5.4.9 (2026-08-10) | <https://www.lua.org/ftp/> |
| `luajit` | LuaJIT 2.1.1794386141 (commit `63c8f1a9`, 2026-11-11) | <https://github.com/LuaJIT/LuaJIT>, branch `v2.1` |

## The quick way: the course's install script

The repository contains the exact script the CI uses. It downloads the Lua
tarballs, **verifies their SHA-256 checksums**, builds everything and creates the
symlinks in `/usr/local/bin`:

```bash
sudo apt install build-essential curl git
scripts/install-interpreters.sh
```

```text
==> Lua 5.5.1
lua-5.5.1.tar.gz: OK
Lua 5.5.1  Copyright (C) 1994-2026 Lua.org, PUC-Rio
==> Lua 5.4.9
lua-5.4.9.tar.gz: OK
Lua 5.4.9  Copyright (C) 1994-2026 Lua.org, PUC-Rio
==> LuaJIT 2.1 @ 63c8f1a9b479ba5518cf6a170ff7729178bc3cfd
LuaJIT 2.1.1794386141 -- Copyright (C) 2005-2026 Mike Pall. https://luajit.org/
```

Environment variables `PREFIX` (default `/opt`), `BINDIR` (default
`/usr/local/bin`) and `SUDO` let you install somewhere else, for example
`PREFIX=$HOME/.local/opt BINDIR=$HOME/.local/bin SUDO= scripts/install-interpreters.sh`.

## The manual way

### PUC-Rio Lua 5.5 and 5.4

Lua builds with nothing but a C compiler and `make`:

```bash
curl -LO https://www.lua.org/ftp/lua-5.5.1.tar.gz
echo "1c4b4068d67061f2a2231ad2b5422e77acea1487ea9890f6320af614f4373dce  lua-5.5.1.tar.gz" | sha256sum -c -
tar xzf lua-5.5.1.tar.gz
cd lua-5.5.1
make linux                 # or: make linux-readline (needs libreadline-dev)
make test                  # prints the version banner: a smoke test
sudo make install INSTALL_TOP=/opt/lua-5.5.1
sudo ln -sf /opt/lua-5.5.1/bin/lua  /usr/local/bin/lua5.5
sudo ln -sf /opt/lua-5.5.1/bin/luac /usr/local/bin/luac5.5
```

Repeat with `5.4.9` (SHA-256 `2335b6c582a52654f94612bf10d2f4672805d05329aa6568b1d8cd9e5c6fb8e6`)
and the `lua5.4` / `luac5.4` names.

`make install` also installs the headers (`include/`) and the static library
`liblua.a` under the `INSTALL_TOP`, which Part 3 uses to embed Lua in C, C++ and Rust.

!!! tip "REPL line editing"
    Lua 5.5's `lua` loads `libreadline.so` dynamically if it can find it
    (`sudo apt install libreadline-dev`, or `export LUA_READLINELIB=libreadline.so.8`).
    For Lua 5.4 build with `make linux-readline`, or use `rlwrap lua5.4`.

!!! note "Distribution packages"
    Ubuntu's `lua5.4` package works for this course, but its patch version lags
    behind lua.org and `lua5.5` may not be packaged yet for your release. Building
    from source takes about ten seconds and gives you the exact versions the
    examples were tested with.

### LuaJIT 2.1

LuaJIT stopped making release tarballs; the `v2.1` branch is a **rolling
release**, and its version number ends with the Unix timestamp of the last
commit (`2.1.1794386141` = 2026-11-11). Build a pinned commit:

```bash
git clone https://github.com/LuaJIT/LuaJIT.git
cd LuaJIT
git checkout 63c8f1a9b479ba5518cf6a170ff7729178bc3cfd
make -j"$(nproc)" PREFIX=/opt/luajit-2.1
sudo make install PREFIX=/opt/luajit-2.1
sudo ln -sf /opt/luajit-2.1/bin/luajit /usr/local/bin/luajit
```

!!! warning "Distribution and bundled LuaJIT builds are older"
    `apt install luajit` gives you a LuaJIT 2.1 snapshot that predates the July 2026
    backport of LuaJIT 3.0 syntax (bitwise operators, `continue`, `const`, …), and
    Neovim and OpenResty ship their own LuaJIT builds, which may also predate it.
    Examples that use that syntax are clearly marked; everything else in Part 1
    sticks to syntax that every LuaJIT 2.1 accepts.

## Check your installation

```bash
lua5.5 -v && lua5.4 -v && luajit -v
```

```text
--8<-- "tests/results/versions.txt"
```

(That block is the version file written by the test runner during the last
test run, with the interpreter id in the first column.)

## Running the course's tests yourself

```bash
git clone https://github.com/pragmaticarun/lua-tutorial.git
cd lua-tutorial
tests/run_all.sh            # all examples on all three interpreters
tests/run_all.sh -v 07-     # verbose, only lesson 7
```

The runner prints a pass/fail/skip table per interpreter. See the repository's
`CONTRIBUTING.md` for the conventions (`-- targets:` headers, per-interpreter
`.expected` overrides, `-- stdin:` input files).

## Building this site locally

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/mkdocs serve        # live preview on http://127.0.0.1:8000
.venv/bin/mkdocs build --strict
```

## Editor support

Any editor works. For completion and diagnostics install
[lua-language-server](https://luals.github.io/) (VS Code extension "Lua" by
sumneko, or via Mason in Neovim) and tell it which runtime you target
(`"runtime.version": "Lua 5.4"` or `"LuaJIT"`). Formatting with StyLua and
linting with luacheck are covered in Lesson 28.

## Part 3 toolchain

Lessons 19–21 compile C and C++ (`sudo apt install build-essential` provides
`gcc` and `g++`). Lesson 22 needs Rust 1.88 or newer:

```bash
curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal
```

`tests/run_all.sh` uses `CC`, `CXX` and `CARGO` from the environment (default
`gcc`, `g++`, `cargo`) and finds each interpreter's headers and static library next
to its binary (`/opt/lua-5.5.1/include`, `/opt/luajit-2.1/include/luajit-2.1`, ...).
