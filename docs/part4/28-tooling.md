# 28. Tooling: LuaRocks, busted, luacheck, StyLua and CI

--8<-- "includes/badges/28-tooling.md"

!!! abstract "What you will be able to do after this lesson"
    - Package a library as a **rock** with a rockspec, and install it into an isolated tree.
    - Write **busted** specs with matchers, spies, stubs and `before_each`, and run them on several Lua versions.
    - Configure **luacheck** for your environment instead of silencing it line by line.
    - Format code with **StyLua** and enforce it in CI.
    - Wire it all into a **GitHub Actions** matrix.

!!! info "Tested versions, and which Lua each tool uses"
    - **LuaRocks 3.13.0**, built from source and configured for Lua 5.4.9; the same
      binary drives Lua 5.5.1 and LuaJIT with `--lua-version`/`--lua-dir`.
    - **busted 2.3.0**, installed three times (one rocks tree per interpreter) so
      the specs really run on Lua 5.4, 5.5 and LuaJIT.
    - **luacheck 1.2.0**, running on Lua 5.4 (it can check code for any version: see `std`).
    - **StyLua 2.6.0**, a Rust binary with no Lua inside. Its parser knows Lua
      5.1-5.4, LuaJIT, Luau and CfxLua, but **not Lua 5.5**: a `global`
      declaration is a parse error (shown below).

## The intuition

| Tool | Role | Closest C++/Rust equivalent |
|---|---|---|
| LuaRocks | package manager and build tool; a *rockspec* describes a package | `cargo` + `Cargo.toml`, or vcpkg/conan |
| busted | BDD-style test runner (`describe`/`it`) with luassert | `cargo test`, GoogleTest |
| luacheck | static analyzer: globals, unused variables, shadowing | `clippy`, clang-tidy |
| StyLua | opinionated formatter | `rustfmt`, clang-format |

!!! note "For C++/Rust developers"
    Lua has no compiler to catch a misspelled variable: `reslt = 1` silently
    creates a global. luacheck is the closest thing to the compiler's
    "undeclared identifier" error, and on a dynamic language it pays for itself
    immediately. Run it in CI exactly like `cargo clippy -- -D warnings`.

## The example project

```text
textkit/
├── textkit-0.1.0-1.rockspec
├── src/textkit/init.lua        require("textkit")
├── src/textkit/wrap.lua        require("textkit.wrap")
├── spec/textkit_spec.lua       busted specs
├── spec/wrap_spec.lua
├── .busted  .luacheckrc  .stylua.toml
└── .github/workflows/ci.yml
```

```lua title="examples/28-tooling/textkit/src/textkit/init.lua"
--8<-- "examples/28-tooling/textkit/src/textkit/init.lua"
```

```lua title="examples/28-tooling/textkit/src/textkit/wrap.lua"
--8<-- "examples/28-tooling/textkit/src/textkit/wrap.lua"
```

## LuaRocks and the rockspec

```lua title="examples/28-tooling/textkit/textkit-0.1.0-1.rockspec"
--8<-- "examples/28-tooling/textkit/textkit-0.1.0-1.rockspec"
```

```bash title="examples/28-tooling/luarocks.test.sh"
--8<-- "examples/28-tooling/luarocks.test.sh"
```

```text title="Output (LuaRocks 3.13.0)"
--8<-- "examples/28-tooling/luarocks.expected"
```

- `luarocks make` builds and installs the rock described by the rockspec in the
  current directory, without downloading the source; `luarocks install name`
  fetches from luarocks.org; `luarocks pack`/`upload` publish.
- `--tree DIR` installs into a project-local tree (like `node_modules`);
  `luarocks path` prints the `LUA_PATH`/`LUA_CPATH` that make it visible.
- The `builtin` build type maps module names to files and compiles C sources
  listed the same way, with no Makefile needed.

## busted

```lua title="examples/28-tooling/textkit/spec/textkit_spec.lua"
--8<-- "examples/28-tooling/textkit/spec/textkit_spec.lua"
```

```lua title="examples/28-tooling/textkit/spec/wrap_spec.lua"
--8<-- "examples/28-tooling/textkit/spec/wrap_spec.lua"
```

```lua title="examples/28-tooling/textkit/.busted"
--8<-- "examples/28-tooling/textkit/.busted"
```

```bash title="examples/28-tooling/busted.test.sh"
--8<-- "examples/28-tooling/busted.test.sh"
```

```text title="Output (busted 2.3.0)"
--8<-- "examples/28-tooling/busted.expected"
```

`assert.are.equal` compares with `==`; `assert.are.same` compares tables deeply.
`-o TAP` produces stable, machine-readable output. The failure report continues
with both tables printed with their memory addresses, which is why the test shows
only its first lines.

## luacheck

```lua title="examples/28-tooling/textkit/.luacheckrc"
--8<-- "examples/28-tooling/textkit/.luacheckrc"
```

```lua title="examples/28-tooling/bad/messy.lua"
--8<-- "examples/28-tooling/bad/messy.lua"
```

```bash title="examples/28-tooling/luacheck.test.sh"
--8<-- "examples/28-tooling/luacheck.test.sh"
```

```text title="Output (luacheck 1.2.0)"
--8<-- "examples/28-tooling/luacheck.expected"
```

Each warning has a code: 1xx globals, 2xx unused variables and arguments, 3xx
unused values, 4xx shadowing, 5xx
unreachable or empty code, 6xx whitespace/style. `std` selects the globals of a
Lua version (`lua51`, `lua54`, `luajit`, `max`, `min`) plus extras like `+busted`,
`ngx_lua` (OpenResty) or custom sets (`read_globals = { "vim" }` for Neovim).

## StyLua

```toml title="examples/28-tooling/textkit/.stylua.toml"
--8<-- "examples/28-tooling/textkit/.stylua.toml"
```

```bash title="examples/28-tooling/stylua.test.sh"
--8<-- "examples/28-tooling/stylua.test.sh"
```

```text title="Output (StyLua 2.6.0)"
--8<-- "examples/28-tooling/stylua.expected"
```

Without a `.stylua.toml`, StyLua uses its defaults (tabs, 120 columns), which is
why the diff from the project root would look different: config is discovered
from the working directory upwards. Pin the StyLua version in CI; formatting
output can change between releases.

## Continuous integration on GitHub Actions

```yaml title="examples/28-tooling/textkit/.github/workflows/ci.yml"
--8<-- "examples/28-tooling/textkit/.github/workflows/ci.yml"
```

!!! warning "What is and is not executed here"
    This workflow file is an example for a standalone `textkit` repository; it is
    **not** run by this site's CI (GitHub only runs workflows from the repository
    root). Its versions were checked against the actions' current releases
    (`leafo/gh-actions-lua@v13` defaults to Lua 5.5, `leafo/gh-actions-luarocks@v6`
    installs LuaRocks 3.13.0, `JohnnyMorganz/stylua-action@v5`). The **commands**
    it runs (`luarocks make`, `busted -o TAP`, `luacheck .`, `luarocks lint`,
    `stylua --check .`) are exactly the ones this page's tests run, with pinned
    tool versions, on every push of this site.

## Hands-on exercises

??? example "Exercise 1: a rockspec for a one-file module"
    Write `slug-1.0-1.rockspec` for `slug.lua`, lint it, install it into a temporary tree, and require it.

    ??? success "Solution"
        ```lua
        --8<-- "examples/28-tooling/ex1/slug-1.0-1.rockspec"
        ```
        ```lua
        --8<-- "examples/28-tooling/ex1/slug.lua"
        ```
        ```bash
        --8<-- "examples/28-tooling/ex1_rockspec.test.sh"
        ```
        ```text
        --8<-- "examples/28-tooling/ex1_rockspec.expected"
        ```

??? example "Exercise 2: stubs and spies"
    Test a shopping cart's `checkout` without a real payment gateway: stub the
    gateway's `charge`, spy on the logger, and rebuild fresh state in `before_each`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/28-tooling/ex2/cart_spec.lua"
        ```
        ```text
        --8<-- "examples/28-tooling/ex2_mocks.expected"
        ```

??? example "Exercise 3: configure luacheck instead of fighting it"
    `legacy.lua` is correct for its host (it uses a global `APP` and Neovim's
    `vim`). Make luacheck report zero warnings with a `.luacheckrc` and one inline
    directive, without changing the code's behaviour.

    ??? success "Solution"
        ```lua
        --8<-- "examples/28-tooling/ex3/legacy.lua"
        ```
        ```lua
        --8<-- "examples/28-tooling/ex3/.luacheckrc"
        ```
        ```text
        --8<-- "examples/28-tooling/ex3_luacheck.expected"
        ```

??? example "Exercise 4: a different house style"
    Configure StyLua for 60 columns, tabs, single quotes and no call parentheses,
    and keep a hand-aligned matrix untouched.

    ??? success "Solution"
        ```toml
        --8<-- "examples/28-tooling/ex4/.stylua.toml"
        ```
        ```lua title="input"
        --8<-- "examples/28-tooling/ex4/input.lua"
        ```
        ```text title="stylua - < input.lua"
        --8<-- "examples/28-tooling/ex4_stylua.expected"
        ```

## Quiz

??? question "Q1. What must the file name of a rockspec match?"
    `<package>-<version>-<revision>.rockspec`, consistent with its `package` and
    `version` fields (e.g. `textkit-0.1.0-1.rockspec` with `version = "0.1.0-1"`).

??? question "Q2. What is the difference between `assert.are.equal` and `assert.are.same`?"
    `equal` uses `==` (identity for tables); `same` compares tables deeply.

??? question "Q3. luacheck reports W111 `setting non-standard global variable`. What are your options?"
    Make it local (usually the bug), or declare the global in `.luacheckrc`
    (`globals = {...}`) if the environment really expects it.

??? question "Q4. Can StyLua 2.6.0 format Lua 5.5 code?"
    Not code that uses 5.5-only syntax: its syntaxes are Lua 5.1-5.4, LuaJIT, Luau
    and CfxLua, and `global x = 1` is a parse error.

??? question "Q5. Why run busted on several interpreters in CI when the code is \"plain Lua\"?"
    Version differences (integer division, `unpack` vs `table.unpack`, string
    formatting of floats, `math.random`) surface only when the code actually runs
    on each version.
