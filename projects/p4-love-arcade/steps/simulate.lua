-- The whole game, autoplayed for up to 20000 frames, with no LÖVE at all:
-- the same Session that main.lua runs inside LÖVE. Prints the event log.
package.path = "../game/?.lua;" .. package.path
local Session = require("src.session")

local s = Session.new(7, print)
print("frame   time state       event      value")
while not s.done and s.frame < 20000 do s.step() end
print(("finished after %d frames (%.1f s of game time)"):format(s.frame, s.game.time))
io.write("high scores:\n", s.saved())
