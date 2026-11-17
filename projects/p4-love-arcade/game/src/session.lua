-- session.lua: one autoplayed game, frame by frame, with a fixed time step.
-- Used by the plain-Lua test (steps/simulate.lua) and by main.lua's --autoplay
-- mode inside LÖVE, so both print the same event log.
local Game = require("src.game")
local Auto = require("src.autopilot")
local RNG = require("src.rng")

local Session = {}

function Session.new(seed, print_line)
  local saved = "1200 LOV\n300 JIT\n"
  local s = { frame = 0, done = false, dt = 1 / 60 }
  s.game = Game.new({
    seed = seed,
    storage = { read = function() return saved end, write = function(text) saved = text end },
    on_event = function(game, name, value)
      print_line(("%5d %6.2fs %-11s %-10s %s"):format(s.frame, game.time, game:state(), name, tostring(value)))
      if name == "quit" then s.done = true end
    end,
  })
  s.auto = Auto.new(RNG.new(seed + 1))
  function s.step()
    s.frame = s.frame + 1
    s.game:update(s.dt, s.auto:input(s.game))
  end
  function s.saved() return saved end
  return s
end

return Session
