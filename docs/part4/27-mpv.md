# 27. mpv Scripting: Events, Properties, Key Bindings, OSD

--8<-- "includes/badges/27-mpv.md"

!!! abstract "What you will be able to do after this lesson"
    - Load Lua scripts into mpv and react to playback **events**.
    - Read, set and observe **properties**, and run commands.
    - Add **key bindings**, receive **script messages**, and read user **options**.
    - Draw on the **OSD** with ASS overlays and `mp.assdraw`.
    - Test player scripts headlessly with `--vo=null --ao=null` and a `lavfi` test source.

!!! info "Which Lua does mpv run?"
    mpv supports **Lua 5.1, Lua 5.2 or LuaJIT**, chosen at build time (most
    distributions use LuaJIT; mpv does not support 5.3+). The tested player is
    **mpv 0.42.0**, compiled from the release source with `-Dlua=luajit` against
    a locked conda-forge environment (LuaJIT `2.1.1744318430`, FFmpeg 9.0.2). We had
    to compile it: the conda-forge mpv package is built **without** Lua. Write
    scripts for 5.1 + LuaJIT: no `//`, no integer subtype.

## The intuition

Each script is a Lua state on its own thread, talking to the player core through
the `mp` module: **events** tell you what happened (`file-loaded`, `seek`,
`end-file`), **properties** are the player's state (`pause`, `time-pos`,
`track-list`), **commands** make things happen (`seek`, `cycle pause`, `quit`).
After your top-level code finishes, the script sits in an event loop and runs
your callbacks one at a time.

!!! note "For C++/Rust developers"
    This is `libmpv`'s client API (`mpv_observe_property`, `mpv_command`,
    `mpv_wait_event`) wrapped for Lua. Everything is asynchronous message passing
    with the core, so a property you just set may not be visible in the same
    callback, and several quick changes to an observed property can be
    **coalesced** into one notification, like an edge-triggered event queue.

## How the examples are tested

```bash
mpv --no-config --vo=null --ao=null --msg-level=all=no,events=info \
    --script=events.lua "av://lavfi:testsrc=duration=3:size=160x120:rate=25"
```

- `av://lavfi:testsrc=...` is an FFmpeg-generated test pattern: no media files needed.
- `--vo=null --ao=null`: decode and "play" without a window or sound card.
- A script's `print` goes to mpv's log as `[scriptname] text`; `--msg-level`
  silences everything else, so stdout contains only the script's lines.
- Two exercises encode a real file first with `mpv --o=` (lavfi streams have no
  known duration, and mpv drops chapters it cannot place).

## Events

```lua title="examples/27-mpv/events.lua"
--8<-- "examples/27-mpv/events.lua"
```

```text title="Output (mpv 0.42.0)"
--8<-- "examples/27-mpv/events.expected"
```

Several handlers may register for one event; they run in registration order.
`quit 4` sets the process exit code, handy for test harnesses.

## Properties

```lua title="examples/27-mpv/properties.lua"
--8<-- "examples/27-mpv/properties.lua"
```

```text title="Output"
--8<-- "examples/27-mpv/properties.expected"
```

- Typed getters: `get_property` (string), `_number`, `_bool`, `_native` (Lua tables
  for lists and maps). They return `nil, error` instead of raising.
- `observe_property` fires once immediately, then on changes. Speed was set to 1.5
  and then doubled in the same callback, but the observer saw only `3`: changes
  are delivered when the script goes idle, and intermediate values are coalesced.
- `expand-text` gives scripts the same `${property}` syntax users write in `input.conf`.

## Key bindings and script messages

```lua title="examples/27-mpv/keybindings.lua"
--8<-- "examples/27-mpv/keybindings.lua"
```

```text title="Output"
--8<-- "examples/27-mpv/keybindings.expected"
```

- `add_key_binding(key, name, fn)` registers a default key that users can rebind
  in `input.conf` with `KEY script-binding <script>/<name>`; `nil` as key means
  "no default". `add_forced_key_binding` overrides the user's `input.conf`.
- `{ complex = true }` delivers `down`/`up`/`repeat`/`press` events.
- `script-message` broadcasts to all scripts; `script-message-to` targets one. The
  same commands work from `input.conf` and from mpv's JSON IPC socket, which makes
  them the way to drive a script from outside.

## The OSD

```lua title="examples/27-mpv/osd.lua"
--8<-- "examples/27-mpv/osd.lua"
```

```text title="Output"
--8<-- "examples/27-mpv/osd.expected"
```

`mp.assdraw` builds ASS drawing commands; `\p4` means drawing coordinates are
scaled by 2^(4-1) = 8 for sub-pixel precision, which is why a 600-pixel bar
appears as `4800`. Overlays use their own `res_x`/`res_y` space, and
`compute_bounds` asks libass where the result landed. Text bounds would depend on
the fonts installed, so the test only measures the vector drawing.

## A practical script: resume playback

```lua title="examples/27-mpv/resume.lua"
--8<-- "examples/27-mpv/resume.lua"
```

```bash title="examples/27-mpv/resume.test.sh"
--8<-- "examples/27-mpv/resume.test.sh"
```

```text title="Output"
--8<-- "examples/27-mpv/resume.expected"
```

- **Hooks** (`on_load`, `on_unload`, ...) pause the player until your handler
  returns; that is how a script can change `start` *before* the file opens, or read
  `time-pos` while the old file is still loaded.
- `mp.options.read_options` reads `script-opts/resume.conf` and `--script-opts=resume-key=value`.
- An exact seek to 2.5 s lands on 2.52 s, the first frame at or after 2.5 s in a
  25 fps stream (frames every 0.04 s).

## Hands-on exercises

??? example "Exercise 1: count pauses"
    Count how many times playback was paused, using `observe_property`, and print the count at shutdown.

    ??? success "Solution"
        ```lua
        --8<-- "examples/27-mpv/ex1_pause_counter.lua"
        ```
        ```text
        --8<-- "examples/27-mpv/ex1_pause_counter.expected"
        ```

??? example "Exercise 2: speed keys with limits"
    Bind `[` / `]` to change speed in 0.25 steps between 0.25x and 4x with an OSD message, and Backspace to reset.

    ??? success "Solution"
        ```lua
        --8<-- "examples/27-mpv/ex2_speed_keys.lua"
        ```
        ```text
        --8<-- "examples/27-mpv/ex2_speed_keys.expected"
        ```

??? example "Exercise 3: skip the intro"
    When a file has a chapter titled "Intro", seek to the start of the next chapter.

    ??? success "Solution"
        ```lua
        --8<-- "examples/27-mpv/ex3_skip_intro.lua"
        ```
        ```bash
        --8<-- "examples/27-mpv/ex3_skip_intro.test.sh"
        ```
        ```text
        --8<-- "examples/27-mpv/ex3_skip_intro.expected"
        ```

??? example "Exercise 4: a clock line"
    Format "position / duration (percent)" in Lua and check it against mpv's own `${...}` expansion.

    ??? success "Solution"
        ```lua
        --8<-- "examples/27-mpv/ex4_clock.lua"
        ```
        ```text
        --8<-- "examples/27-mpv/ex4_clock.expected"
        ```

## Quiz

??? question "Q1. Which Lua versions can mpv be built with?"
    Lua 5.1, Lua 5.2 or LuaJIT, one chosen at build time; 5.3+ is not supported.

??? question "Q2. You set `speed` three times in one callback. How many times does an observer of `speed` fire?"
    Possibly once, with the final value: notifications are delivered when the
    script is idle and intermediate values may be coalesced.

??? question "Q3. How does a user rebind a key your script added with `add_key_binding('b', 'bookmark', f)`?"
    In `input.conf`: `Ctrl+b script-binding <scriptname>/bookmark`.

??? question "Q4. Why use an `on_load` hook rather than the `file-loaded` event to set a start position?"
    The hook runs before the file is opened and blocks loading until it returns,
    so the `start` option takes effect; at `file-loaded` the file is already open.

??? question "Q5. How can another program trigger a function in your script?"
    Send `script-message` / `script-message-to` through mpv's JSON IPC socket (or
    bind it in `input.conf`); the script handles it with `mp.register_script_message`.
