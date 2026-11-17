-- host: love
-- Collector: a tiny LÖVE game. Run it:   love game
-- Headless test:  xvfb-run -a love game --frames 600 --autoplay
local World = require("world")
local Input = require("input")

local world, input
local opts = { frames = nil, autoplay = false }

-- scripted key events for --autoplay: frame -> { "press"/"release", key }
local script = {
  [1] = { "press", "right" }, [40] = { "press", "down" }, [70] = { "release", "down" },
  [120] = { "release", "right" }, [121] = { "press", "left" }, [200] = { "press", "up" },
  [260] = { "release", "up" }, [300] = { "release", "left" }, [301] = { "press", "d" },
  [302] = { "press", "s" }, [420] = { "release", "d" }, [500] = { "release", "s" },
}

function love.load(args)
  for i, a in ipairs(args) do
    if a == "--frames" then opts.frames = tonumber(args[i + 1]) end
    if a == "--autoplay" then opts.autoplay = true end
  end
  love.graphics.setDefaultFilter("nearest", "nearest")
  world = World.new(42)
  input = Input.new({ left = { "left", "a" }, right = { "right", "d" },
                      up = { "up", "w" }, down = { "down", "s" }, quit = { "escape" } })
end

-- LÖVE calls these from its event loop; we just forward to Input
function love.keypressed(key) input:keypressed(key) end
function love.keyreleased(key) input:keyreleased(key) end

function love.update(dt)
  if input:wasPressed("quit") then love.event.quit() end
  world:update(dt, input)
  input:endFrame()
end

function love.draw()
  local g = love.graphics
  g.clear(0.1, 0.1, 0.15)
  g.setColor(0.5, 0.5, 0.6)
  for _, w in ipairs(world.walls) do g.rectangle("fill", w.x, w.y, w.w, w.h) end
  g.setColor(1, 0.85, 0.2)
  for _, c in ipairs(world.coins) do g.circle("fill", c.x, c.y, c.r) end
  g.setColor(0.9, 0.2, 0.2)
  for _, h in ipairs(world.hazards) do g.circle("fill", h.x, h.y, h.r) end
  g.setColor(0.2, 0.8, 0.4)
  local p = world.player
  g.rectangle("fill", p.x, p.y, p.w, p.h)
  g.setColor(1, 1, 1)
  g.print(("score %d  hits %d"):format(world.score, world.hits), 4, 4)
end

-- love.run is the main loop. The default one measures real time between
-- frames; for a reproducible test we replace it with a fixed 1/60 s step,
-- inject the scripted keys, and quit after N frames.
if arg and table.concat(arg, " "):find("--frames", 1, true) then
  function love.run()
    love.load(love.arg.parseGameArguments(arg))
    local frame, dt = 0, 1 / 60
    local canvas = love.graphics.newCanvas(320, 240)
    return function()                       -- called once per frame
      love.event.pump()
      for name, a, b, c, d, e, f in love.event.poll() do
        if name == "quit" then return 0 end
        love.handlers[name](a, b, c, d, e, f)
      end
      frame = frame + 1
      local step = opts.autoplay and script[frame]
      if step then love.event.push(step[1] == "press" and "keypressed" or "keyreleased", step[2], step[2], false) end
      love.update(dt)
      love.graphics.setCanvas(canvas)       -- draw off-screen so we can read pixels
      love.draw()
      love.graphics.setCanvas()
      love.graphics.origin()
      love.graphics.draw(canvas)
      love.graphics.present()
      if frame == opts.frames then
        local img = canvas:newImageData()
        local function px(x, y)
          local r, g, b = img:getPixel(x, y)
          return ("(%d,%d,%d)"):format(r * 255 + 0.5, g * 255 + 0.5, b * 255 + 0.5)
        end
        local p = world.player
        print(("frames=%d time=%.3f score=%d hits=%d over=%s"):format(
          frame, world.time, world.score, world.hits, tostring(world.over)))
        print(("player=(%.2f,%.2f) coins=%d"):format(p.x, p.y, #world.coins))
        print("pixel player centre " .. px(p.x + 8, p.y + 8))
        print("pixel wall          " .. px(world.walls[1].x + 2, world.walls[1].y + 2))
        print("pixel background    " .. px(319, 239))
        return 0                            -- exit status of the process
      end
    end
  end
end
