# 24. LÖVE: Game Loop, Input, Drawing, Collisions

--8<-- "includes/badges/24-love.md"

!!! abstract "What you will be able to do after this lesson"
    - Explain LÖVE's callbacks (`love.load`, `love.update`, `love.draw`, input events) and its main loop `love.run`.
    - Separate game logic from engine calls so it can be tested with plain Lua.
    - Implement AABB, circle and circle-box collisions and resolve overlaps.
    - Use a fixed timestep, map keys to actions, and run a game headlessly for N frames.

!!! info "Which Lua does LÖVE run?"
    LÖVE 11.x embeds **LuaJIT**. The tested build, the official **LÖVE 11.5**
    `love-11.5-x86_64.AppImage` (the latest release, December 2023), reports
    `Lua 5.1 / LuaJIT 2.1.1700008891`. Game code must therefore stay within Lua 5.1 +
    LuaJIT: no `//`, no integer subtype, no `<close>`. The pure-logic modules on
    this page are also run under Lua 5.5 and 5.4 to prove they are portable.

## The intuition

A game is a loop: **read input → update the world by `dt` seconds → draw**, about
60 times a second. LÖVE owns the loop and calls your functions:

```text
love.load(arg)                 once
loop:
  poll OS events  ->  love.keypressed / love.keyreleased / love.mousepressed / ... / love.quit
  dt = time since last frame
  love.update(dt)
  love.graphics.origin(); clear; love.draw(); present
```

That loop *is* the function `love.run`, written in Lua, and you can replace it.

!!! note "For C++/Rust developers"
    LÖVE is an SDL2 + OpenGL engine written in C++ with the whole API bound into
    LuaJIT. The split you would make in C++ or Rust (an engine-independent
    simulation core, a thin rendering/input layer) is just as valuable here: the
    simulation becomes unit-testable under any Lua, and the engine-specific part
    shrinks to a few callbacks.

## How the examples are tested

- **Logic modules** (`collision`, `input`, `world`) contain no `love.*` calls and
  are tested with plain `lua5.5`, `lua5.4` and `luajit`.
- **The game** runs in the real LÖVE 11.5 under a virtual X server
  (`xvfb-run`, Mesa's software OpenGL), with a custom `love.run` that uses a
  fixed `dt`, injects scripted key events, quits after N frames, and reads back
  pixels from the frame it drew.

## Callbacks and their order

```lua title="examples/24-love/callbacks/main.lua"
--8<-- "examples/24-love/callbacks/main.lua"
```

```lua title="examples/24-love/callbacks/conf.lua"
--8<-- "examples/24-love/callbacks/conf.lua"
```

```bash title="examples/24-love/callbacks.test.sh"
--8<-- "examples/24-love/callbacks.test.sh"
```

```text title="Output (LÖVE 11.5 under xvfb)"
--8<-- "examples/24-love/callbacks.expected"
```

The pushed `keypressed` event is delivered by the *first* event poll, before the
first `love.update`. `love.event.quit()` only queues a `quit` event: the current
frame still draws, then `love.quit` runs on the next poll (and could veto it).

## Collisions

```lua title="examples/24-love/game/collision.lua"
--8<-- "examples/24-love/game/collision.lua"
```

```lua title="examples/24-love/collision_test.lua"
--8<-- "examples/24-love/collision_test.lua"
```

```text title="Output (Lua 5.5, 5.4 and LuaJIT)"
--8<-- "examples/24-love/collision_test.expected"
```

- Strict `<` makes touching edges *not* a collision; decide this once and stick to it.
- Circle vs box uses the **closest point** of the box to the circle's centre: near
  corners the bounding boxes overlap while the shapes do not.
- `resolve` returns the **minimum translation vector**: push out along the axis
  with the least overlap. That is what lets a player stand on a platform but
  slide along a wall.

## Input as actions, not keys

```lua title="examples/24-love/game/input.lua"
--8<-- "examples/24-love/game/input.lua"
```

```lua title="examples/24-love/input_test.lua"
--8<-- "examples/24-love/input_test.lua"
```

```text title="Output"
--8<-- "examples/24-love/input_test.expected"
```

`love.keyboard.isDown("left")` asks the OS about the physical keyboard, which a test
cannot press. Tracking state from `love.keypressed`/`love.keyreleased` events
instead makes the game scriptable, rebindable, and testable.

## The game: world, main and a headless harness

```lua title="examples/24-love/game/world.lua"
--8<-- "examples/24-love/game/world.lua"
```

```lua title="examples/24-love/game/conf.lua"
--8<-- "examples/24-love/game/conf.lua"
```

```lua title="examples/24-love/game/main.lua"
--8<-- "examples/24-love/game/main.lua"
```

```bash title="examples/24-love/game.test.sh"
--8<-- "examples/24-love/game.test.sh"
```

```text title="Output (LÖVE 11.5, Mesa llvmpipe)"
--8<-- "examples/24-love/game.expected"
```

The pixel colours are what the canvas really contains: `(0.2, 0.8, 0.4)` is stored
as 8-bit `(51, 204, 102)`, and `0.5` rounds to `127`. Because the world only
depends on its seed, the fixed `dt` and the scripted keys, the same simulation
can be replayed **without LÖVE**, and must agree:

```lua title="examples/24-love/world_test.lua"
--8<-- "examples/24-love/world_test.lua"
```

```text title="Output (Lua 5.5, 5.4 and LuaJIT)"
--8<-- "examples/24-love/world_test.expected"
```

!!! warning "Same numbers on every Lua"
    The world uses its own random generator. `math.random` differs between Lua
    5.4/5.5 (xoshiro256\*\*) and LuaJIT, and the classic `s * 1103515245 + 12345`
    LCG overflows 2^53, where LuaJIT's doubles lose precision but 5.4's integers
    do not. The Park-Miller generator keeps every product below 2^53, so all
    three interpreters and LÖVE produce identical worlds.

## Hands-on exercises

??? example "Exercise 1: push a circle out of a box"
    Return the shortest vector that separates a circle from a box, including the
    case where the circle's centre is inside the box.

    ??? success "Solution"
        ```lua
        --8<-- "examples/24-love/ex1_circle_push.lua"
        ```
        ```text
        --8<-- "examples/24-love/ex1_circle_push.expected"
        ```

??? example "Exercise 2: a fixed-timestep accumulator"
    Advance a simulation in fixed 1/60 s steps whatever the frame times, cap
    huge frames, and compute the interpolation factor for drawing.

    ??? success "Solution"
        ```lua
        --8<-- "examples/24-love/ex2_fixed_step.lua"
        ```
        ```text
        --8<-- "examples/24-love/ex2_fixed_step.expected"
        ```

??? example "Exercise 3: sprite animation"
    Write an animation object that picks the sprite-sheet frame for looping and
    one-shot animations at a given frame rate.

    ??? success "Solution"
        ```lua
        --8<-- "examples/24-love/ex3_animation.lua"
        ```
        ```text
        --8<-- "examples/24-love/ex3_animation.expected"
        ```

??? example "Exercise 4: a spatial hash"
    Reduce pairwise collision checks among 200 boxes with a uniform grid, and
    show it finds exactly the same overlaps as brute force.

    ??? success "Solution"
        ```lua
        --8<-- "examples/24-love/ex4_spatial_hash.lua"
        ```
        ```text
        --8<-- "examples/24-love/ex4_spatial_hash.expected"
        ```

## Quiz

??? question "Q1. In which order does LÖVE call `love.load`, `love.update` and `love.draw`, and where do key events arrive?"
    `love.load` once; then every frame: events (`love.keypressed`, ...) during the
    poll, then `love.update(dt)`, then `love.draw()`.

??? question "Q2. Why is `love.keyboard.isDown` awkward in tests, and what replaces it?"
    It reads the physical keyboard. Tracking state from key events (an input
    module fed by `love.keypressed`/`keyreleased`) can be driven by scripted events.

??? question "Q3. What problem does a fixed timestep solve?"
    With a variable `dt`, results (collisions, jumps) depend on the frame rate.
    Fixed steps make the simulation deterministic and stable; the leftover time
    is used only to interpolate drawing.

??? question "Q4. Two boxes share an edge exactly (a.x + a.w == b.x). Do they collide in this lesson's `aabb`?"
    No: the test uses strict `<`, so touching is not overlapping.

??? question "Q5. Which Lua runs inside LÖVE 11.5, and name one operator you therefore cannot use?"
    LuaJIT 2.1 (Lua 5.1 semantics); `//` (and the 5.3 bitwise operators) do not exist.
