-- Replay the --autoplay script without LÖVE: same seed, same fixed step,
-- same keys, so the result must equal the in-engine run (game.expected).
package.path = "game/?.lua;" .. package.path
local World = require("world")
local Input = require("input")

local script = {
  [1] = { "press", "right" }, [40] = { "press", "down" }, [70] = { "release", "down" },
  [120] = { "release", "right" }, [121] = { "press", "left" }, [200] = { "press", "up" },
  [260] = { "release", "up" }, [300] = { "release", "left" }, [301] = { "press", "d" },
  [302] = { "press", "s" }, [420] = { "release", "d" }, [500] = { "release", "s" },
}
local world = World.new(42)
local input = Input.new({ left = { "left", "a" }, right = { "right", "d" },
                          up = { "up", "w" }, down = { "down", "s" } })
local pending
for frame = 1, 600 do
  -- in LÖVE a pushed event is delivered on the next frame's poll
  if pending then input[pending[1] == "press" and "keypressed" or "keyreleased"](input, pending[2]) end
  pending = script[frame]
  world:update(1 / 60, input)
  input:endFrame()
  if frame % 150 == 0 then
    print(("frame %3d score=%d hits=%d player=(%.2f,%.2f)"):format(
      frame, world.score, world.hits, world.player.x, world.player.y))
  end
end
print(("frames=600 time=%.3f score=%d hits=%d over=%s"):format(
  world.time, world.score, world.hits, tostring(world.over)))
