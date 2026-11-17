-- host: love
-- The order in which LÖVE calls your callbacks, with the default love.run.
-- Run: xvfb-run -a love callbacks
local frame = 0
local function log(fmt, ...) print(("[frame %d] " .. fmt):format(frame, ...)) end

function love.load(args)
  log("love.load (%d game args), window %dx%d", #args, love.graphics.getDimensions())
  love.event.push("keypressed", "space", "space", false)   -- as if the user pressed space
end

function love.keypressed(key, scancode, isrepeat)
  log("love.keypressed %s (scancode %s, repeat %s)", key, scancode, tostring(isrepeat))
end

function love.update(dt)
  frame = frame + 1
  log("love.update dt>0: %s", tostring(dt >= 0))
  if frame == 3 then love.event.quit(0) end          -- queues a "quit" event
end

function love.draw()
  log("love.draw")
end

function love.quit()
  log("love.quit")
  return false        -- returning true would abort the quit
end
