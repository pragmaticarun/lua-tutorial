# Project 3. A Neovim Plugin: Project Notes and a Task Picker

--8<-- "includes/badges/p3-notes-nvim.md"

!!! abstract "What you will build"
    `notes.nvim`: every project gets a Markdown notes file (`.notes.md` at the
    project root, found from the current buffer). `:NoteAdd text #tag @2026-11-20`
    appends a task, `:Notes` opens the file in a floating window, and `:Tasks
    [tags]` opens a **picker**: overdue tasks are highlighted, ++enter++ toggles
    a task done (and saves the file), ++o++ jumps to it, ++q++ closes. Tags
    complete on the command line, and `:checkhealth notes` reports problems.
    The plugin is tested **headless in real Neovim 0.12.6**, with keys fed
    exactly as a user would type them.

    Uses: [patterns (7)](../part1/07-patterns.md), [modules (12)](../part2/12-modules.md),
    [Neovim (23)](../part4/23-neovim.md).
    Source: `projects/p3-notes-nvim/`.

## Design first

A Neovim plugin is a directory on `'runtimepath'` with a conventional layout:

```text
p3-notes-nvim/
├── plugin/notes.lua       sourced at startup: only defines commands
├── lua/notes/init.lua     the plugin (loaded on first use): config, files, UI
├── lua/notes/tasks.lua    pure logic: parse, filter, sort, format, toggle
└── lua/notes/health.lua   :checkhealth notes
```

- **Lazy loading by construction.** `plugin/notes.lua` runs at every Neovim
  start, so it only registers three commands whose callbacks `require("notes")`.
  Startup cost is three `nvim_create_user_command` calls; no plugin manager
  tricks needed.
- **The file is the database.** Tasks are Markdown list items, `- [ ] text #tag @YYYY-MM-DD`,
  so the notes stay readable on GitHub and in any editor. Line numbers are the
  task ids.
- **A pure core.** `notes.tasks` turns lines into task tables and back, with no
  `vim.*` call, so it runs (and is tested) on Lua 5.5, 5.4 and LuaJIT. Neovim
  itself embeds **LuaJIT** (2.1.1774638290 in the tested build), i.e. Lua 5.1
  semantics, so the core sticks to 5.1.
- **Edit through buffers.** If `.notes.md` is open in a buffer, changes go
  through that buffer (and it is written), never behind its back, so the user
  does not get "file changed on disk" warnings or lose unsaved edits.
- **Injectable "today".** `setup({ today = function() ... end })` exists so the
  overdue highlighting can be tested on any date.

!!! note "For C++/Rust developers"
    `plugin/` vs `lua/` is the split between a tiny always-linked registration
    unit and a lazily `dlopen`ed library. Neovim's API is a C API
    (`nvim_buf_set_lines`, `nvim_open_win`) exposed to Lua as `vim.api.*`;
    buffers, windows and namespaces are integer handles. Extmarks are like
    "anchored ranges" in an editor model: they move with edits, unlike stored
    byte offsets.

## Step 1: the task model in plain Lua

```lua title="projects/p3-notes-nvim/lua/notes/tasks.lua"
--8<-- "projects/p3-notes-nvim/lua/notes/tasks.lua"
```

```lua title="projects/p3-notes-nvim/steps/tasks_demo.lua"
--8<-- "projects/p3-notes-nvim/steps/tasks_demo.lua"
```

```text title="Output (Lua 5.5, 5.4 and LuaJIT)"
--8<-- "projects/p3-notes-nvim/steps/tasks_demo.expected"
```

Dates in ISO format compare correctly **as strings** (`"2026-11-10" < "2026-11-17"`),
so no date library is needed for "overdue".

## Step 2: commands at startup

```lua title="projects/p3-notes-nvim/plugin/notes.lua"
--8<-- "projects/p3-notes-nvim/plugin/notes.lua"
```

The `vim.g.loaded_notes` guard keeps the file idempotent if it is sourced twice.
`complete` returns candidate tags for `:Tasks <Tab>`; it is the first thing that
loads `lua/notes`.

## Step 3: the plugin: root, file, float, picker

```lua title="projects/p3-notes-nvim/lua/notes/init.lua"
--8<-- "projects/p3-notes-nvim/lua/notes/init.lua"
```

Points to study:

- `vim.fs.root(0, markers)` (Neovim 0.10+) walks up from the current buffer's
  file to the first directory containing `.git` (or the other markers).
- The picker is an unlisted scratch buffer (`nvim_create_buf(false, true)`, wiped when hidden) in a floating window, made
  read-only after filling it, with **buffer-local** mappings.
- The picker captures the notes **path when it opens**. The first version asked
  for the root again inside the ++enter++ handler, but by then the current buffer
  is the nameless picker, so `vim.fs.root` fell back to the working directory and
  wrote the wrong file. The headless test caught it.
- Highlights are extmarks in the plugin's own namespace, so clearing them never
  touches anyone else's.

## Step 4: health check

```lua title="projects/p3-notes-nvim/lua/notes/health.lua"
--8<-- "projects/p3-notes-nvim/lua/notes/health.lua"
```

## Step 5: testing in headless Neovim

`nvim --headless --clean -l notes_test.lua` runs a Lua file in a real editor
with no UI and no user config. The test installs the plugin the way a plugin
manager would (prepend to `'runtimepath'`, source `plugin/`), creates a throw-away
project with a `.git` directory, then uses commands and **typed keys**
(`nvim_feedkeys` with the `x` flag, which executes them immediately):

```lua title="projects/p3-notes-nvim/tests/notes_test.lua"
--8<-- "projects/p3-notes-nvim/tests/notes_test.lua"
```

```text title="Output (Neovim 0.12.6, LuaJIT 2.1)"
--8<-- "projects/p3-notes-nvim/tests/notes_test.expected"
```

The temporary root path differs on every run, so the test prints it as
`<root>`. Under `-l`, `print` goes to the message area (stderr), which is why the
test writes its report with `io.write`.

!!! info "Version notes"
    - Requires **Neovim 0.10+**: `vim.fs.root`, `vim.uv` and `vim.fs.joinpath`
      appeared in 0.10; the health check says so. Only 0.12.6 was run here.
    - Window `title` / `title_pos` need 0.9+. `nvim_win_get_config(win).title`
      returns a list of `{text, highlight}` chunks, hence `title[1][1]` in the test.
    - The `✅ OK` prefix is how recent Neovim versions format health output;
      it has changed before, so tests should not depend on it across versions.

## Extension exercises

??? example "Exercise 1: priorities"
    Treat `!!` in the text as high and `!` as medium priority, and sort open tasks
    by priority before due date.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p3-notes-nvim/exercises/ex1_priority.lua"
        ```
        ```text
        --8<-- "projects/p3-notes-nvim/exercises/ex1_priority.expected"
        ```

??? example "Exercise 2: progress per tag"
    Print a text progress bar for each tag.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p3-notes-nvim/exercises/ex2_progress.lua"
        ```
        ```text
        --8<-- "projects/p3-notes-nvim/exercises/ex2_progress.expected"
        ```

??? example "Exercise 3: archive finished tasks"
    Move done tasks into a `## Done` section at the end of the file, creating it
    if needed and leaving everything else in place.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p3-notes-nvim/exercises/ex3_archive.lua"
        ```
        ```text
        --8<-- "projects/p3-notes-nvim/exercises/ex3_archive.expected"
        ```

??? example "Exercise 4: live virtual text (tested in Neovim)"
    Show `N open / M` as virtual text after the `## Tasks` heading of any
    `.notes.md` buffer, updated as you type.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p3-notes-nvim/tests/ex4_virtual_text.lua"
        ```
        ```text
        --8<-- "projects/p3-notes-nvim/tests/ex4_virtual_text.expected"
        ```

## Quiz

??? question "Q1. What belongs in `plugin/` and what in `lua/`?"
    `plugin/` is sourced at every startup, so only cheap registration (commands,
    autocommands, mappings) goes there; the real code lives in `lua/` and is
    loaded by `require` on first use.

??? question "Q2. How does the plugin find the project root?"
    `vim.fs.root(0, root_markers)`: walk up from the current buffer's file to the
    first directory containing a marker such as `.git`, falling back to the cwd.

??? question "Q3. Why did the picker originally write the wrong file?"
    It recomputed the root inside the key handler, where the current buffer is
    the nameless picker buffer; capturing the path when the picker opens fixes it.

??? question "Q4. Why is `today` a configurable function?"
    So tests (and users in odd setups) can control the date; otherwise the
    "overdue" output would change every day.

??? question "Q5. Which Lua version does a Neovim plugin target?"
    Lua 5.1 semantics: Neovim is built with LuaJIT (or, rarely, PUC Lua 5.1).
    So `//`, bitwise operators, `utf8` and other 5.3+ features are out; LuaJIT
    extras such as `bit` and `goto` work in practice but not on a 5.1 build.
