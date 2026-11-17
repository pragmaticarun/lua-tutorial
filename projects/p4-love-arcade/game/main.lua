-- Brick Rush. Play:  love game     (arrows/A-D move, Space launches, P pauses)
-- Test:  xvfb-run -a love game --autoplay --snapshot 600
--   plays one autoplayed game with a fixed 1/60 s step, prints the event log
--   (identical to steps/simulate.lua on plain Lua) and samples pixels.
local Game = require("src.game")
local Session = require("src.session")

local SCALE = 2
local game, canvas, pressed = nil, nil, {}

local function storage()               -- high scores in LÖVE's save directory
  return {
    read = function() return love.filesystem.read("scores.txt") end,
    write = function(text) love.filesystem.write("scores.txt", text) end,
  }
end

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")   -- crisp pixels when scaled
  canvas = love.graphics.newCanvas(320, 240)
  game = Game.new({ seed = os.time(), storage = storage(),
                    on_event = function(_, name) if name == "quit" then love.event.quit() end end })
end

function love.keypressed(key) pressed[#pressed + 1] = key end

function love.update(dt)
  local kb = love.keyboard
  game:update(math.min(dt, 1 / 30), {     -- clamp dt: a stall must not teleport the ball
    left = kb.isDown("left", "a"), right = kb.isDown("right", "d"), pressed = pressed,
  })
  pressed = {}
end

local function render(g_game)
  local g = love.graphics
  g.setCanvas(canvas)                     -- draw at 320x240, then scale up
  g.clear(0.08, 0.08, 0.12)
  g_game:draw(g)
  g.setCanvas()
  g.setColor(1, 1, 1)
  g.draw(canvas, 0, 0, 0, SCALE, SCALE)
end

function love.draw() render(game) end

-- The test mode replaces love.run (the main loop) so time advances by exactly
-- 1/60 s per frame and input comes from the autopilot.
local function arg_value(name)
  for i, a in ipairs(arg or {}) do if a == name then return arg[i + 1] or true end end
end
if arg_value("--autoplay") then
  function love.run()
    love.load()
    local s = Session.new(7, print)
    local snapshot = tonumber(arg_value("--snapshot")) or -1
    print("frame   time state       event      value")
    return function()
      love.event.pump()
      for name in love.event.poll() do
        if name == "quit" then return 0 end
      end
      s.step()
      render(s.game)
      love.graphics.present()
      if s.frame == snapshot then
        local img = canvas:newImageData()
        local function px(x, y)
          local r, g, b = img:getPixel(math.floor(x), math.floor(y))
          return ("(%d,%d,%d)"):format(r * 255 + 0.5, g * 255 + 0.5, b * 255 + 0.5)
        end
        local play = s.game.sm.stack[1]
        local brick, pad = play.bricks[1], play.paddle
        print(("snapshot at frame %d: state %s, %d bricks, paddle x=%.1f"):format(
          s.frame, s.game:state(), #play.bricks, pad.x))
        print("  paddle     " .. px(pad.x + pad.w / 2, pad.y + 2))
        print("  brick      " .. px(brick.x + 3, brick.y + 3))
        print("  background " .. px(1, 239))
      end
      if s.done or s.frame >= 20000 then
        print(("finished after %d frames (%.1f s of game time)"):format(s.frame, s.game.time))
        io.write("high scores:\n", s.saved())
        return 0
      end
    end
  end
end
