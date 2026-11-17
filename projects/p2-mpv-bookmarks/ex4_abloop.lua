-- Exercise 4 (solution): Ctrl+a loops the section between the bookmarks
-- around the current position, using mpv's A-B loop properties. A single-file
-- script, so it adds the bookmarks directory to package.path itself.
local mp = require("mp")
local options = require("mp.options")
local here = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = here .. "bookmarks/?.lua;" .. package.path
local Store = require("store")

local opts = { file = "", demo_at = -1 }
options.read_options(opts, "abloop")

local function load_store()
  local f = io.open(opts.file, "r")
  if not f then return Store.new() end
  local s = Store.parse(f:read("*a"))
  f:close()
  return s
end

local function loop_here()
  local store, now = load_store(), mp.get_property_number("time-pos", 0)
  local a, b
  for _, item in ipairs(store.items) do
    if item.time <= now then a = item elseif not b then b = item end
  end
  if not (a and b) then
    print("need a bookmark before and after " .. Store.format_time(now))
    return
  end
  mp.set_property_number("ab-loop-a", a.time)
  mp.set_property_number("ab-loop-b", b.time)
  print(("looping %s .. %s (%s -> %s)"):format(Store.format_time(a.time), Store.format_time(b.time),
    a.title, b.title))
end
mp.add_key_binding("ctrl+a", "loop", loop_here)

-- demo mode for the test: seek, press the key, show the properties, quit
local restarts = 0
mp.register_event("playback-restart", function()
  if opts.demo_at < 0 then return end
  restarts = restarts + 1
  if restarts == 1 then
    mp.commandv("seek", tostring(opts.demo_at), "absolute+exact")
  elseif restarts == 2 then
    loop_here()
    print("ab-loop-a = " .. mp.get_property("ab-loop-a") .. ", ab-loop-b = " .. mp.get_property("ab-loop-b"))
    mp.command("quit")
  end
end)
