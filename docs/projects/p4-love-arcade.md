# Project 4. A Complete LÖVE Arcade Game

--8<-- "includes/badges/p4-love-arcade.md"

!!! abstract "What you will build"
    **Brick Rush**, a complete brick-breaker for [LÖVE](https://love2d.org) 11.5:
    a title screen, three levels, lives, combo scoring, a pause menu, a "level
    clear" screen, game over with initials entry and a persistent top-5
    high-score table. The game logic is pure Lua and is tested on **Lua 5.5, 5.4
    and LuaJIT**; then the **real LÖVE binary** plays a whole autoplayed game
    (under a virtual X server) and must produce exactly the same event log, frame
    for frame, plus the right pixels on screen.

    Uses: [closures (9)](../part1/09-closures.md), [metatables (10)](../part2/10-metatables.md),
    [OOP (11)](../part2/11-oop.md), [modules (12)](../part2/12-modules.md), [LÖVE (24)](../part4/24-love.md). Source: `projects/p4-love-arcade/`.

## Design first

Games are hard to test when logic, input, time and drawing are tangled in
`love.update`. Four decisions untangle them:

1. **A state machine with a stack.** Title, play, pause, level clear and game
   over are separate tables with optional `enter/exit/update/keypressed/draw`.
   `switch` replaces the top state, `push` puts pause *on top of* play (play
   keeps its state but stops updating), `pop` resumes.
2. **Input is data.** `update(dt, input)` receives `{left=, right=, pressed={...}}`.
   The keyboard produces it in `main.lua`; the **autopilot** produces the same
   table in tests and for an attract mode.
3. **Fixed time step.** Physics advances in fixed sub-steps, and the test loop
   advances exactly 1/60 s per frame, so a run is reproducible.
4. **Our own RNG.** `math.random` uses different algorithms in Lua 5.4/5.5
   (xoshiro256\*\*) and LuaJIT, so the same seed gives different games. A
   20-line Park-Miller generator gives identical sequences everywhere.

Everything the game *does* is reported as an event (`brick`, `level`,
`pause`, `highscore`, ...) through one callback. Sound effects would hang off
it; here the tests print it.

```text
main.lua (love.*)  ──input──▶  Game ──▶ StateMachine ──▶ title | play | pause | level_clear | game_over
   ▲  draw(g)                    │                          │
   └────────────────────────────  └── events ──▶ log / sounds / tests
```

!!! note "For C++/Rust developers"
    This is the classic "game loop with fixed update and variable render"
    (Glenn Fiedler's *Fix Your Timestep*), with states as a stack of trait
    objects / virtual interfaces. In Lua a "trait object" is any table with the
    right fields: `SM:update` simply checks `if state.update then`. There is no
    ECS here, and none is needed at this size. Integer-valued scores stay exact
    in doubles up to 2^53 on every interpreter.

## Step 1: random numbers you control

```lua title="projects/p4-love-arcade/game/src/rng.lua"
--8<-- "projects/p4-love-arcade/game/src/rng.lua"
```

## Step 2: a state machine with a stack

```lua title="projects/p4-love-arcade/game/src/statemachine.lua"
--8<-- "projects/p4-love-arcade/game/src/statemachine.lua"
```

## Step 3: physics and levels

```lua title="projects/p4-love-arcade/game/src/physics.lua"
--8<-- "projects/p4-love-arcade/game/src/physics.lua"
```

```lua title="projects/p4-love-arcade/game/src/levels.lua"
--8<-- "projects/p4-love-arcade/game/src/levels.lua"
```

Levels are strings, so designing one is typing it.

## Step 4: the play state

```lua title="projects/p4-love-arcade/game/src/play.lua"
--8<-- "projects/p4-love-arcade/game/src/play.lua"
```

Details that came out of testing:

- The ball moves in **4 sub-steps** per update so a fast ball cannot tunnel
  through a thin brick.
- Where the ball hits the paddle sets its angle; `P.scale` then rescales the
  velocity to the ball's current speed, which grows 4% per brick up to
  `MAX_SPEED`. The angle is capped (`offset * 0.9`), so the ball never moves
  perfectly horizontally.
- The autopilot (step 7) originally aimed only once per serve and could get
  stuck bouncing in a loop that never reached the last bricks; it now re-aims
  after every paddle bounce.
- The combo multiplier (bricks hit without touching the paddle) is **capped at
  ×4**, so one lucky ricochet cannot dominate the score.
- `draw(g)` takes the graphics module as a parameter, so `play.lua` itself
  never references the global `love`.

## Step 5: the other screens, scores and the game object

```lua title="projects/p4-love-arcade/game/src/states.lua"
--8<-- "projects/p4-love-arcade/game/src/states.lua"
```

```lua title="projects/p4-love-arcade/game/src/highscores.lua"
--8<-- "projects/p4-love-arcade/game/src/highscores.lua"
```

```lua title="projects/p4-love-arcade/game/src/game.lua"
--8<-- "projects/p4-love-arcade/game/src/game.lua"
```

High scores go through a tiny `storage` object (`read`/`write`): in LÖVE it is
`love.filesystem` (the save directory named by `t.identity`), in tests a string.

## Step 6: unit tests on every interpreter

```lua title="projects/p4-love-arcade/steps/logic_test.lua"
--8<-- "projects/p4-love-arcade/steps/logic_test.lua"
```

```text title="Output (Lua 5.5, 5.4 and LuaJIT)"
--8<-- "projects/p4-love-arcade/steps/logic_test.expected"
```

## Step 7: a whole game without LÖVE

The autopilot tracks the ball, re-aims after each paddle bounce, launches,
pauses once, and types initials at game over:

```lua title="projects/p4-love-arcade/game/src/autopilot.lua"
--8<-- "projects/p4-love-arcade/game/src/autopilot.lua"
```

```lua title="projects/p4-love-arcade/game/src/session.lua"
--8<-- "projects/p4-love-arcade/game/src/session.lua"
```

```lua title="projects/p4-love-arcade/steps/simulate.lua"
--8<-- "projects/p4-love-arcade/steps/simulate.lua"
```

??? info "Output: the full event log (112 lines, identical on Lua 5.5, 5.4 and LuaJIT)"
    ```text
    --8<-- "projects/p4-love-arcade/steps/simulate.expected"
    ```

All three levels are cleared in 8916 frames (148.6 s of game time) for 3105
points, which lands at the top of the table as `LUA`.

## Step 8: the LÖVE side, and a real frame run

```lua title="projects/p4-love-arcade/game/conf.lua"
--8<-- "projects/p4-love-arcade/game/conf.lua"
```

```lua title="projects/p4-love-arcade/game/main.lua"
--8<-- "projects/p4-love-arcade/game/main.lua"
```

The game draws into a 320×240 canvas with nearest-neighbour filtering and
scales it ×2: crisp pixels at any window size. In normal play `dt` is clamped
to 1/30 s so a stall (dragging the window) cannot teleport the ball. With
`--autoplay`, `main.lua` replaces `love.run` (LÖVE's main loop) with one that
advances exactly 1/60 s per frame, renders every frame through the real
renderer, and at frame 600 reads pixels back from the canvas.

```bash title="projects/p4-love-arcade/game.test.sh"
--8<-- "projects/p4-love-arcade/game.test.sh"
```

```text title="Output (LÖVE 11.5, LuaJIT 2.1, Xvfb + Mesa llvmpipe)"
--8<-- "projects/p4-love-arcade/game.expected"
```

The pixel colours are the paddle, a one-hit brick and the background, the
`setColor` values quantised to 8 bits (the clear colour 0.08, 0.08, 0.12 reads back as 20, 20, 31).

!!! info "Version and platform notes"
    - LÖVE 11.5 embeds **LuaJIT** (2.1.1700008891 here), so game code is
      Lua 5.1: no `//`, no integer subtype. The pure modules are additionally
      checked on 5.4 and 5.5 to keep them portable (e.g. for a future LÖVE 12
      or another engine).
    - The **same event log on three interpreters and inside LÖVE** is real,
      but it depends on IEEE-754 doubles evaluated identically. That holds for
      these interpreters on x86-64; floating-point replays across different
      CPUs, compilers or `-ffast-math` builds are not guaranteed in general,
      which is why networked games often use fixed-point math.
    - `conf.lua` disables the audio module, because the CI machine has no sound
      device (LÖVE would otherwise abort at start-up).
    - LÖVE 12 (in development) changes some APIs; only 11.5 was tested.

## Extension exercises

??? example "Exercise 1: an extra life every 1000 points"
    Add it without editing `play.lua`: listen to the events.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p4-love-arcade/exercises/ex1_extra_life.lua"
        ```
        ```text
        --8<-- "projects/p4-love-arcade/exercises/ex1_extra_life.expected"
        ```

??? example "Exercise 2: record and replay"
    Record each frame's input, then feed it to a fresh game with the same seed
    and show both runs end identically.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p4-love-arcade/exercises/ex2_replay.lua"
        ```
        ```text
        --8<-- "projects/p4-love-arcade/exercises/ex2_replay.expected"
        ```

??? example "Exercise 3: validate level layouts"
    Reject levels with wrong row widths, unknown characters or no bricks before
    the game uses them.

    ??? success "Solution"
        ```lua
        --8<-- "projects/p4-love-arcade/exercises/ex3_validate.lua"
        ```
        ```text
        --8<-- "projects/p4-love-arcade/exercises/ex3_validate.expected"
        ```

??? example "Exercise 4: sound effects"
    Play a short sound on `brick` and `level` events in `main.lua`. Generate
    the sounds with `love.sound.newSoundData` so no asset files are needed,
    and remember that `conf.lua` currently disables audio.

    ??? success "Solution"
        Re-enable audio in `conf.lua` (`t.modules.audio = true`, `t.modules.sound = true`),
        then in `main.lua`:

        ```lua
        local function beep(freq, seconds)
          local rate = 22050
          local data = love.sound.newSoundData(math.floor(rate * seconds), rate, 16, 1)
          for i = 0, data:getSampleCount() - 1 do
            data:setSample(i, 0.3 * math.sin(2 * math.pi * freq * i / rate))
          end
          return love.audio.newSource(data, "static")
        end
        local sounds = { brick = beep(660, 0.05), level = beep(440, 0.3) }
        -- in love.load, extend on_event:
        --   on_event = function(_, name)
        --     if sounds[name] then sounds[name]:clone():play() end
        --     if name == "quit" then love.event.quit() end
        --   end
        ```

        This one is **not** run in CI (no audio device there); `clone()` lets
        several bricks sound at once.

## Quiz

??? question "Q1. Why does pause use `push` and not `switch`?"
    `push` keeps the play state (ball, bricks, score) under the pause screen;
    `pop` returns to it unchanged. `switch` would call play's `exit` and drop it.

??? question "Q2. Why not use `math.random` with a fixed seed?"
    Lua 5.4/5.5 and LuaJIT use different generators, so the same seed gives
    different sequences; a self-contained RNG is identical everywhere.

??? question "Q3. What makes the LÖVE run comparable to the plain-Lua run?"
    The same `Session` code, a fixed 1/60 s step per frame (custom `love.run`),
    scripted input from the autopilot and the seeded RNG.

??? question "Q4. Why does the ball move in sub-steps?"
    To avoid tunnelling: a big step could carry it past a thin brick without
    any overlapping position being tested.

??? question "Q5. Which Lua does LÖVE 11.5 run?"
    LuaJIT 2.1 (Lua 5.1 semantics plus LuaJIT extensions such as `bit` and FFI).
