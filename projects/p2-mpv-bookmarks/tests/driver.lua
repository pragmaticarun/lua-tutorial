-- driver.lua: plays the user. Loaded next to the bookmarks script, it runs a
-- scenario written as straight-line code: a coroutine that yields until the
-- event or script message it waits for arrives.
local mp = require("mp")
local scenario = mp.get_opt("driver-scenario") or "first"

local co, waiting
local queue = { restart = {}, done = {} }   -- events that arrived before we waited
local unpack = table.unpack or unpack

local function wait(what)
  if #queue[what] > 0 then return unpack(table.remove(queue[what], 1)) end
  waiting = what
  return coroutine.yield()
end
local function wake(what, ...)
  if waiting ~= what then                    -- not waiting for this yet: keep it
    table.insert(queue[what], { ... })
    return
  end
  waiting = nil
  local ok, err = coroutine.resume(co, ...)
  if not ok then print("driver error: " .. tostring(err)) mp.command("quit 3") end
end
mp.register_event("playback-restart", function() wake("restart") end)
mp.register_script_message("bookmarks-done", function(action, n) wake("done", action, n) end)

local function pos() return ("%.2f"):format(mp.get_property_number("time-pos")) end
local function seek(t) mp.commandv("seek", tostring(t), "absolute+exact") wait("restart") end
local function key(k)
  print("press " .. k .. " at " .. pos())
  mp.commandv("keypress", k)
  return wait("done")
end
local function jump(k)                -- a jump key that finds a bookmark also seeks
  key(k)
  wait("restart")
  print("now at " .. pos())
end

co = coroutine.create(function()
  local _, n = wait("done")           -- the bookmarks script loaded its file
  print("bookmarks script ready, " .. n .. " bookmarks")
  wait("restart")                     -- playback (paused) has started
  if scenario == "first" then
    seek(2); key("ctrl+b")
    seek(7.5)
    mp.commandv("script-message", "bookmarks-add", "Credits")
    wait("done")
    seek(4); key("ctrl+b")
    seek(4.2); key("ctrl+b")          -- within 0.5 s: moves the bookmark
    key("ctrl+l")
    jump("ctrl+n")                    -- 4.2 -> 7.5
    jump("ctrl+p")                    -- 7.5 -> 4.2
    jump("ctrl+p")                    -- 4.2 -> 2.0
    key("ctrl+p")                     -- nothing before 2.0
    key("ctrl+d")                     -- deletes the one at 2.0
    key("ctrl+e")
    for i, c in ipairs(mp.get_property_native("chapter-list")) do
      print(("chapter %d: %.2f %s"):format(i, c.time, c.title))
    end
  else
    key("ctrl+l")
  end
  mp.command("quit")
end)
coroutine.resume(co)
