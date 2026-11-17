-- Exercise 2 (solution): record every frame's input, then replay it into a
-- fresh game with the same seed. Fixed time step + seeded RNG = same game.
package.path = "../game/?.lua;" .. package.path
local Game = require("src.game")
local Auto = require("src.autopilot")
local RNG = require("src.rng")

local function run(inputs_or_nil)
  local quit = false
  local game = Game.new({ seed = 3, on_event = function(_, name) if name == "quit" then quit = true end end })
  local auto, recorded, frame = Auto.new(RNG.new(4)), {}, 0
  while not quit and frame < 20000 do
    frame = frame + 1
    local input = inputs_or_nil and inputs_or_nil[frame] or auto:input(game)
    recorded[frame] = input
    game:update(1 / 60, input)
  end
  local top = game.scores[1]
  return recorded, frame, top and top.score or 0
end

local recorded, frames, score = run(nil)
print(("recorded %d frames, final score %d"):format(frames, score))
local _, frames2, score2 = run(recorded)
print(("replayed %d frames, final score %d, identical: %s"):format(frames2, score2,
  tostring(frames == frames2 and score == score2)))
