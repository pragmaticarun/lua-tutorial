-- Exercise 1 (solution): an extra life every 1000 points, without touching
-- play.lua: listen to the "brick" events and look at the play state.
package.path = "../game/?.lua;" .. package.path
local Session = require("src.session")

local lines = {}
local s = Session.new(7, function(line) lines[#lines + 1] = line end)
local next_bonus = 1000
local old = s.game.on_event
s.game.on_event = function(game, name, value)
  old(game, name, value)
  if name == "brick" then
    local play = game.sm:top()
    if play.score and play.score >= next_bonus then
      play.lives = play.lives + 1
      next_bonus = next_bonus + 1000
      print(("frame %d: score %d -> extra life (now %d)"):format(s.frame, play.score, play.lives))
    end
  end
end
while not s.done and s.frame < 20000 do s.step() end
print(lines[#lines - 4])                  -- the "won"/"game_over" line
