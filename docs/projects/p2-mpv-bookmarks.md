# Project 2. An mpv Bookmark and Chapter Manager

--8<-- "includes/badges/p2-mpv-bookmarks.md"

!!! abstract "What you will build"
    A plugin for the [mpv](https://mpv.io) media player: press ++ctrl+b++ to
    bookmark the current position, ++ctrl+n++ / ++ctrl+p++ to jump between
    bookmarks, ++ctrl+d++ to delete the nearest one, ++ctrl+l++ to list them on the
    on-screen display and ++ctrl+e++ to turn them into real chapters. Bookmarks
    persist per media file. The plugin is tested **inside real mpv 0.42**
    (headless, with a generated test video), driven by a second script that
    "presses the keys".

    Uses: [tables (4–5)](../part1/05-tables-2.md), [modules (12)](../part2/12-modules.md),
    [coroutines (14)](../part2/14-coroutines.md), [mpv scripting (27)](../part4/27-mpv.md). Source: `projects/p2-mpv-bookmarks/`.

## Design first

mpv plugins are Lua scripts reacting to **key bindings, events and property
changes**. The trap is to write all logic inside those callbacks, where it can
only be tested by clicking around. So the plugin has two layers:

| File | Knows about mpv? | Responsibility |
|---|---|---|
| `bookmarks/store.lua` | **no** | a sorted list of `{time, title}`; add (merging near-duplicates), remove, next/previous, formatting, chapter conversion, (de)serialisation |
| `bookmarks/main.lua` | yes | key bindings, file I/O, OSD messages, events, the `chapter-list` property |

Because `store.lua` is plain Lua it runs (and is tested) on **Lua 5.5, 5.4 and
LuaJIT**; `main.lua` runs in mpv, whose bundled Lua here is **LuaJIT
2.1.1744318430** (mpv can also be built against Lua 5.1 or 5.2; it does not
support 5.3+). So `main.lua` must stay 5.1-compatible.

Rules that make it pleasant:

- **Merge window.** A bookmark within `MERGE = 0.5` s of an existing one *moves*
  it instead of adding a near-duplicate. Next/previous skip anything within the
  same window, so pressing ++ctrl+n++ right after a jump goes to the *following*
  bookmark instead of the one you are sitting on.
- **A script directory.** `bookmarks/main.lua` makes the plugin a directory
  under `~~/scripts/`; mpv puts the directory on `package.path`, so
  `require("store")` just works.
- **Announce, don't assume.** After every action the plugin broadcasts
  `script-message bookmarks-done ACTION COUNT`. Other scripts (and our tests)
  can react without polling.

!!! note "For C++/Rust developers"
    `store.lua` is the "domain model" and `main.lua` the "adapter" of a
    hexagonal design. A Lua module returning a table with a metatable-backed
    `new` is the equivalent of a small class; `Store.MERGE` is a public
    `static constexpr`/`const` you can tune in tests. mpv calls your callbacks
    on its single script thread, one event at a time, so there is no locking:
    each script is its own Lua state, like an actor.

## Step 1: the store, outside mpv

```lua title="projects/p2-mpv-bookmarks/bookmarks/store.lua"
--8<-- "projects/p2-mpv-bookmarks/bookmarks/store.lua"
```

Exercise it with plain Lua first:

```lua title="projects/p2-mpv-bookmarks/steps/store_demo.lua"
--8<-- "projects/p2-mpv-bookmarks/steps/store_demo.lua"
```

```text title="Output (Lua 5.5, 5.4 and LuaJIT)"
--8<-- "projects/p2-mpv-bookmarks/steps/store_demo.expected"
```

`next_after` and `prev_before` end with an explicit `return nil`. Without it a
function that "falls off the end" returns **no value**, and `tostring(f())`
then fails with "bad argument #1 to 'tostring' (value expected)", a bug this
project hit during development.

## Step 2: tests without a framework

You can use busted (Project 1) here as well; this step shows how little you
need for a dependency-free check list:

```lua title="projects/p2-mpv-bookmarks/steps/store_test.lua"
--8<-- "projects/p2-mpv-bookmarks/steps/store_test.lua"
```

```text title="Output"
--8<-- "projects/p2-mpv-bookmarks/steps/store_test.expected"
```

## Step 3: the mpv side

```lua title="projects/p2-mpv-bookmarks/bookmarks/main.lua"
--8<-- "projects/p2-mpv-bookmarks/bookmarks/main.lua"
```

Install it by copying (or symlinking) the `bookmarks/` directory into
`~/.config/mpv/scripts/`. Notes on the mpv API used:

- `mp.add_key_binding(key, name, fn)`: the *name* lets users rebind it in
  `input.conf` as `ctrl+B script-binding bookmarks/add`.
- `options.read_options(opts, "bookmarks")` reads
  `~~/script-opts/bookmarks.conf` and `--script-opts=bookmarks-dir=...`.
- `seek <t> absolute+exact`: without `+exact` mpv seeks to a keyframe.
- `chapter-list` is a **writable** property: setting it creates chapters that
  mpv's own chapter keys and on-screen controller use.

## Step 4: testing in real mpv

The test runs mpv with no window and no audio (`--vo=null --ao=null`), paused,
with two scripts: ours and a **driver**. The driver is written as a coroutine,
so the scenario reads top to bottom although every step waits for an mpv event:

```lua title="projects/p2-mpv-bookmarks/tests/driver.lua"
--8<-- "projects/p2-mpv-bookmarks/tests/driver.lua"
```

The queue is there because mpv sometimes delivers `playback-restart` *before*
our `bookmarks-done` message for the same action; without it the first version
of this driver waited forever. The shell side creates a real 10-second video
(lavfi sources have no duration, so it is encoded with mpv's own `--o`),
runs two sessions and shows the saved file:

```bash title="projects/p2-mpv-bookmarks/bookmarks.test.sh"
--8<-- "projects/p2-mpv-bookmarks/bookmarks.test.sh"
```

```text title="Output (mpv 0.42.0, LuaJIT 2.1)"
--8<-- "projects/p2-mpv-bookmarks/bookmarks.expected"
```

!!! info "Why 7.52 and not 7.5?"
    The test video has 25 frames per second, so frames sit at multiples of
    0.04 s. 7.5 s falls between two frames, and an exact seek lands on the
    next frame, **7.52**; that is where "Credits" was bookmarked. The list
    shows `00:07.5` because `format_time` rounds to tenths. Real media behaves
    the same way, so bookmark times are only as precise as the frame rate.

!!! info "Version notes"
    - mpv 0.42.0 here embeds LuaJIT 2.1 (built from source on the box and in CI).
      Distribution builds may use Lua 5.1 or 5.2; the plugin uses nothing
      beyond 5.1.
    - `store.lua` is tested on Lua 5.5, 5.4 and LuaJIT; it uses only 5.1
      features (no `//`, no `table.move`, no `utf8`).
    - Only the mpv 0.42.0 build listed in the badge was tested; the APIs used
      (`add_key_binding`, `read_options`, `script-message`, writable
      `chapter-list`) are long-standing, but older mpv versions were not run.

## Extension exercises

??? example "Exercise 1: FFmpeg chapter export"
    Write the bookmarks as an FFMETADATA file so `ffmpeg -map_metadata` can bake
    them into the media. Each chapter ends where the next begins.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p2-mpv-bookmarks/exercises/ex1_ffmetadata.lua"
        ```
        ```text
        --8<-- "projects/p2-mpv-bookmarks/exercises/ex1_ffmetadata.expected"
        ```

??? example "Exercise 2: import existing chapters"
    Turn a file's chapters (the `chapter-list` property, a list of
    `{time=, title=}`) into bookmarks without duplicating existing ones.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p2-mpv-bookmarks/exercises/ex2_import.lua"
        ```
        ```text
        --8<-- "projects/p2-mpv-bookmarks/exercises/ex2_import.expected"
        ```

??? example "Exercise 3: smarter default titles"
    Name a new bookmark after the chapter it falls in plus the offset, e.g.
    `Chapter 2 +00:12.5`.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p2-mpv-bookmarks/exercises/ex3_titles.lua"
        ```
        ```text
        --8<-- "projects/p2-mpv-bookmarks/exercises/ex3_titles.expected"
        ```

??? example "Exercise 4: A-B loop between bookmarks (tested in mpv)"
    Bind ++ctrl+a++ to loop the section between the bookmarks around the current
    position, using the `ab-loop-a` / `ab-loop-b` properties.

    ??? success "Solution"
        ```lua title="ex4_abloop.lua"
        --8<-- "projects/p2-mpv-bookmarks/ex4_abloop.lua"
        ```
        ```bash title="ex4_abloop.test.sh"
        --8<-- "projects/p2-mpv-bookmarks/ex4_abloop.test.sh"
        ```
        ```text
        --8<-- "projects/p2-mpv-bookmarks/ex4_abloop.expected"
        ```

## Quiz

??? question "Q1. Why is `store.lua` free of any `mp.*` call?"
    So the logic can be tested with any Lua interpreter (and busted), quickly and
    deterministically; only the thin `main.lua` needs a real mpv.

??? question "Q2. How does `require(\"store\")` find `store.lua` inside mpv?"
    The plugin is a script *directory* (`scripts/bookmarks/main.lua`); mpv adds
    that directory to `package.path` before running `main.lua`.

??? question "Q3. What does a function that ends without `return` give `tostring`?"
    No value at all, which `tostring` rejects ("value expected"). An explicit
    `return nil` returns one value, `nil`.

??? question "Q4. Why does the driver queue events?"
    mpv may deliver the `playback-restart` event before the plugin's
    `bookmarks-done` message; a coroutine waiting for one would miss the other.

??? question "Q5. Which Lua versions can an mpv script rely on?"
    Lua 5.1 semantics: mpv is built against LuaJIT (as here), Lua 5.1 or 5.2,
    never 5.3+.
