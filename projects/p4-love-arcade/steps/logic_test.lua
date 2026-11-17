-- Unit checks for the game's pure-Lua parts; runs on Lua 5.5, 5.4 and LuaJIT.
package.path = "../game/?.lua;" .. package.path
local P = require("src.physics")
local SM = require("src.statemachine")
local H = require("src.highscores")
local RNG = require("src.rng")
local Play = require("src.play")

local n, failed = 0, 0
local function check(name, cond)
  n = n + 1
  if not cond then failed = failed + 1; print("FAIL " .. name) end
end

-- physics
check("circle misses rect", P.circle_rect(0, 0, 3, 10, 10, 5, 5) == false)
local hit, axis = P.circle_rect(12, 8, 3, 10, 10, 20, 5)        -- from above
check("hit from above bounces on y", hit and axis == "y")
hit, axis = P.circle_rect(8, 12, 3, 10, 10, 20, 5)               -- from the left
check("hit from the side bounces on x", hit and axis == "x")
local x, y = P.scale(3, -4, 10)
check("scale keeps direction and sets length", x == 6 and y == -8)

-- state machine: enter/exit/resume order
local log = {}
local function state(name)
  return { enter = function() log[#log + 1] = "enter " .. name end,
           exit = function() log[#log + 1] = "exit " .. name end,
           resume = function() log[#log + 1] = "resume " .. name end }
end
local sm = SM.new()
sm:push(state("title")); sm:switch(state("play")); sm:push(state("pause")); sm:pop()
check("state machine order", table.concat(log, ",") ==
  "enter title,exit title,enter play,enter pause,exit pause,resume play")

-- high scores
local list = H.parse("500 AAA\n300 BBB\n")
check("parse", #list == 2 and list[2].name == "BBB")
check("insert ranks", H.insert(list, 400, "CCC") == 2 and list[3].name == "BBB")
for i = 1, 5 do H.insert(list, i, "Z") end
check("keeps the best five", #list == 5 and list[4].score == 5 and list[5].score == 4)
check("qualifies only above the 5th", H.qualifies(list, 5) and not H.qualifies(list, 4) and not H.qualifies(list, 0))
check("round trip", H.serialize(H.parse(H.serialize(list))) == H.serialize(list))

-- RNG: same seed, same sequence
local a, b = RNG.new(42), RNG.new(42)
check("rng repeats", a:next() == b:next() and a:range(1, 6) == b:range(1, 6))

-- gameplay with a stub game object
local events = {}
local stub = { rng = RNG.new(1), event = function(_, name, v) events[#events + 1] = name .. ":" .. tostring(v) end,
               level_cleared = function() events[#events + 1] = "cleared" end }
local play = Play.new(stub, 1)
check("level 1 has 26 bricks", #play.bricks == 26)
play:update(1, { right = true })
check("paddle stops at the wall", play.paddle.x == 320 - 48)
check("ball rides the paddle", play.ball.x == play.paddle.x + 24)
play:keypressed("space")
check("launch goes up", play.ball.vy < 0 and not play.ball.stuck)
local frames = 0
while #events < 2 and frames < 600 do play:update(1 / 60, {}); frames = frames + 1 end
check("first brick hit within 600 frames", events[2] == "brick:10")
print(("%d checks, %d failed (first brick after %d frames)"):format(n, failed, frames))
