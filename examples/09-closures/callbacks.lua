-- callbacks.lua: an event emitter, the way host APIs (mpv, Neovim) use closures
local function new_emitter()
  local handlers = {}
  local emitter = {}
  function emitter.on(event, fn)
    handlers[event] = handlers[event] or {}
    table.insert(handlers[event], fn)
  end
  function emitter.emit(event, ...)
    for _, fn in ipairs(handlers[event] or {}) do fn(...) end
  end
  return emitter
end

local player = new_emitter()
local watched = 0                                    -- state shared with a callback
player.on("time-pos", function(t) watched = t end)
player.on("end-file", function(reason)
  print(("finished (%s) after %d s"):format(reason, watched))
end)
for t = 1, 3 do player.emit("time-pos", t * 10) end
player.emit("end-file", "eof")
