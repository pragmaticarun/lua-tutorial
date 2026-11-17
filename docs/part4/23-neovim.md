# 23. Neovim: Configuration and Plugins in Lua

--8<-- "includes/badges/23-neovim.md"

!!! abstract "What you will be able to do after this lesson"
    - Write a Neovim configuration in Lua: options, mappings, autocommands, user commands.
    - Use `vim.api`, `vim.fn`, `vim.keymap`, `vim.opt` and the event loop (`vim.uv`, `vim.schedule`).
    - Structure a small plugin (`plugin/` + `lua/`), with `setup()`, namespaces and extmarks.
    - Test editor code headlessly with `nvim --headless -l`, the way this page's examples are tested.

!!! info "Which Lua does Neovim run?"
    Neovim embeds **LuaJIT** (Lua 5.1 semantics plus LuaJIT extensions) in its
    official builds. The tested build, **Neovim 0.12.6** (official
    `nvim-linux-x86_64.tar.gz`), reports `Lua 5.1 / LuaJIT 2.1.1774638290`. So:
    no integer subtype, no `//` or `&`/`|`/`~` operators, no `<const>`/`<close>`,
    no `global` declarations; use `bit` for bit operations and `jit`/`ffi` if you need them.
    Neovim can be built against PUC Lua 5.1 too, so plugins should not *require* `jit`.

## The intuition

Neovim is a C program with a Lua interpreter inside, and nearly everything the
editor can do is exposed to that interpreter:

| Namespace | What it is |
|---|---|
| `vim.api.nvim_*` | The **API**: the same functions remote clients call over RPC. Stable, typed, 0-based where it says so. |
| `vim.fn.*` | Every **Vimscript function** (`vim.fn.expand`, `vim.fn.getqflist`, ...). |
| `vim.cmd` | Run **Ex commands** (`vim.cmd("write")`, `vim.cmd.edit(path)`). |
| `vim.o`, `vim.bo`, `vim.wo`, `vim.opt`, `vim.g`, `vim.b` | **Options** (global/buffer/window, list-aware) and **variables**. |
| `vim.keymap`, `vim.api.nvim_create_autocmd`, `nvim_create_user_command` | **Mappings, events, commands**. |
| `vim.uv`, `vim.schedule`, `vim.system` | The **libuv event loop** under the editor. |

Your config (`~/.config/nvim/init.lua`) and every plugin are just Lua files that
call these functions at startup.

!!! note "For C++/Rust developers"
    Think of Neovim as a host application exposing a C API to an embedded
    scripting engine, exactly like Lesson 20, but generated: `vim.api` functions
    are produced from the C API's metadata, so they validate argument types and
    raise Lua errors instead of crashing. Buffers, windows and namespaces are
    integer *handles* (like file descriptors), not objects; `0` means "current".

## How the examples are tested

Every example on this page is a Lua file run by the real editor:

```bash
nvim --headless --clean -l api_basics.lua
```

- `--headless`: no UI; `--clean`: no user config or plugins, so results are reproducible.
- `-l file.lua`: run the script as the main program (Neovim 0.9+), then exit; a Lua error exits non-zero.
- In this mode `print()` goes to Neovim's message area, which headless Neovim writes to **stderr**.
  The examples therefore write their test output with `io.write` through a small `say()` helper.

## Buffers, lines and options

```lua title="examples/23-neovim/api_basics.lua"
--8<-- "examples/23-neovim/api_basics.lua"
```

```text title="Output (Neovim 0.12.6)"
--8<-- "examples/23-neovim/api_basics.expected"
```

- **Indexing:** `nvim_buf_get_lines`/`set_lines` take **0-based, end-exclusive** line
  ranges (`-1` = end); `nvim_win_get_cursor` returns a **1-based row** and a
  **0-based byte column**. Mixing these is the most common plugin bug.
- `vim.bo[buf].x` / `vim.wo[win].x` target a specific buffer/window; `vim.o.x`
  behaves like `:set` (for a buffer-local option it reads the current buffer's value;
  use `vim.go` for the global value).
- `vim.opt` returns option *objects* with `:append`, `:remove`, `:prepend` for
  list and map options (`wildignore`, `listchars`, `shortmess`).

## Mappings with `vim.keymap.set`

```lua title="examples/23-neovim/keymaps.lua"
--8<-- "examples/23-neovim/keymaps.lua"
```

```text title="Output"
--8<-- "examples/23-neovim/keymaps.expected"
```

- The right-hand side can be a string of keys or a Lua function; `desc` documents it.
- `expr = true`: the function *returns* keys to execute. `buffer = n`: buffer-local.
  `vim.keymap.set` defaults to `noremap` (set `remap = true` to opt out).
- Tests drive mappings with `nvim_feedkeys(keys, "xt", false)`: `x` executes now,
  `t` handles keys as if typed. `vim.keycode("<leader>w")` replaces the older
  `nvim_replace_termcodes` dance.

## Autocommands

```lua title="examples/23-neovim/autocmds.lua"
--8<-- "examples/23-neovim/autocmds.lua"
```

```text title="Output"
--8<-- "examples/23-neovim/autocmds.expected"
```

Notice the order: setting `filetype` *inside* the `BufNewFile` callback fires
`FileType` immediately, before the `BufNewFile` callback prints. Autocommands
nest. Always put yours in an augroup created with `clear = true`, so sourcing
the file twice does not register everything twice.

## User commands

```lua title="examples/23-neovim/user_commands.lua"
--8<-- "examples/23-neovim/user_commands.lua"
```

```text title="Output"
--8<-- "examples/23-neovim/user_commands.expected"
```

## The event loop: `vim.schedule`, timers and processes

```lua title="examples/23-neovim/async.lua"
--8<-- "examples/23-neovim/async.lua"
```

```text title="Output"
--8<-- "examples/23-neovim/async.expected"
```

!!! warning "Fast events"
    Callbacks from libuv (timers, process exit, file watchers) run in a *fast
    event* context where most `vim.api` functions raise `E5560`. Wrap them with
    `vim.schedule_wrap` (or call `vim.schedule` inside) to run on the main loop.
    `vim.wait` pumps the loop, which is what makes this headless test possible.

## A real config, split into modules

```lua title="examples/23-neovim/config/init.lua"
--8<-- "examples/23-neovim/config/init.lua"
```

=== "lua/user/options.lua"
    ```lua
    --8<-- "examples/23-neovim/config/lua/user/options.lua"
    ```
=== "lua/user/keymaps.lua"
    ```lua
    --8<-- "examples/23-neovim/config/lua/user/keymaps.lua"
    ```
=== "lua/user/autocmds.lua"
    ```lua
    --8<-- "examples/23-neovim/config/lua/user/autocmds.lua"
    ```

`require("user.options")` works because Neovim adds `lua/` under every
`'runtimepath'` directory to the module search, and `~/.config/nvim` is the first
entry. The test loads the config the same way and checks what it did:

```lua title="examples/23-neovim/config_test.lua"
--8<-- "examples/23-neovim/config_test.lua"
```

```text title="Output"
--8<-- "examples/23-neovim/config_test.expected"
```

## Writing a plugin: `todo.nvim`

A plugin is a directory on `'runtimepath'` (plugin managers just clone it and
add it there). Two directories matter:

- `plugin/*.lua` is **sourced at startup**. Keep it tiny: define commands, and
  `require` the real code lazily inside them.
- `lua/<name>/*.lua` holds modules loaded on first `require`. Expose a
  `setup(opts)` that merges user options over defaults.

```lua title="examples/23-neovim/todo.nvim/plugin/todo.lua"
--8<-- "examples/23-neovim/todo.nvim/plugin/todo.lua"
```

```lua title="examples/23-neovim/todo.nvim/lua/todo/init.lua"
--8<-- "examples/23-neovim/todo.nvim/lua/todo/init.lua"
```

Extmarks are positions that move with the text as it is edited; a **namespace**
groups them so the plugin can clear only its own. The test loads the plugin
from `'runtimepath'` and drives it through its commands and API:

```lua title="examples/23-neovim/plugin_test.lua"
--8<-- "examples/23-neovim/plugin_test.lua"
```

```text title="Output"
--8<-- "examples/23-neovim/plugin_test.expected"
```

!!! tip "Testing plugins in CI"
    `nvim --headless --clean -l test.lua` with `assert` is all you need; a failing
    assertion exits non-zero. Larger plugins use `busted` with `nlua` or
    `mini.test`/`plenary.nvim` as runners, but they still start Neovim the same way.

## Hands-on exercises

??? example "Exercise 1: an option toggler"
    Write `toggle(name)` that flips any boolean option in the right scope (window,
    buffer or global), a `:Toggle {option}` command with completion, and
    `<leader>tw` / `<leader>ts` mappings for `wrap` and `spell`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/23-neovim/ex1_toggle.lua"
        ```
        ```text
        --8<-- "examples/23-neovim/ex1_toggle.expected"
        ```

??? example "Exercise 2: trim trailing whitespace on save"
    Strip trailing whitespace in a `BufWritePre` autocommand, keep the cursor and
    view where they were, do not pollute the search history, and skip markdown.

    ??? success "Solution"
        ```lua
        --8<-- "examples/23-neovim/ex2_trim.lua"
        ```
        ```text
        --8<-- "examples/23-neovim/ex2_trim.expected"
        ```

??? example "Exercise 3: surround the word under the cursor"
    Map `<leader>"` and `<leader>(` to wrap the word under the cursor in quotes or
    parentheses with `nvim_buf_set_text`.

    ??? success "Solution"
        ```lua
        --8<-- "examples/23-neovim/ex3_surround.lua"
        ```
        ```text
        --8<-- "examples/23-neovim/ex3_surround.expected"
        ```

??? example "Exercise 4: extend todo.nvim"
    Without editing the plugin, add `todo.count(buf)` and a `:TodoCount` command
    that prints the number of each keyword, sorted.

    ??? success "Solution"
        ```lua
        --8<-- "examples/23-neovim/ex4_todo_count.lua"
        ```
        ```text
        --8<-- "examples/23-neovim/ex4_todo_count.expected"
        ```

## Quiz

??? question "Q1. Which Lua does an official Neovim 0.12 build run, and what does that rule out?"
    LuaJIT 2.1 (Lua 5.1 semantics). No integer subtype, no `//`, no `<const>`/`<close>`
    attributes, no 5.3+ bitwise operators (use `bit.band` etc.).

??? question "Q2. `nvim_buf_get_lines(0, 2, 3, true)` returns which line?"
    The third line: ranges are 0-based and end-exclusive. The cursor API, by
    contrast, uses 1-based rows.

??? question "Q3. Why create autocommands inside `nvim_create_augroup(name, { clear = true })`?"
    Re-sourcing the file clears the group first, so autocommands are not duplicated.
    It also lets you list or delete them by group.

??? question "Q4. A libuv timer callback calls `vim.api.nvim_set_current_line` and fails with E5560. Why, and what is the fix?"
    uv callbacks run in a fast event context where most API calls are not allowed.
    Wrap the callback with `vim.schedule_wrap` (or call `vim.schedule` inside it).

??? question "Q5. What belongs in `plugin/x.lua` versus `lua/x/init.lua`?"
    `plugin/` is sourced at every startup, so only cheap definitions (commands,
    mappings) that `require` the module lazily; the implementation lives in `lua/x/`.
