-- host: mpv
-- A practical script: remember where each file was stopped and resume there.
-- Uses mp.options (user-configurable settings) and mp.utils (JSON, paths).
local utils = require("mp.utils")
local options = require("mp.options")

-- defaults; users override them in script-opts/resume.conf or with
-- --script-opts=resume-state_file=...,resume-min_position=...
local opts = { state_file = "/tmp/mpv-resume.json", min_position = 0.5,
               demo_seek = -1 }  -- only for the test: seek here, then quit
options.read_options(opts, "resume")

local function load_state()
  local f = io.open(opts.state_file, "r")
  if not f then return {} end
  local data = utils.parse_json(f:read("*a")) or {}
  f:close()
  return data
end

local function save_state(state)
  local f = assert(io.open(opts.state_file, "w"))
  f:write(utils.format_json(state))
  f:close()
end

local key -- identifies the current file

-- on_load hooks run before the file is opened: the place to set "start"
mp.add_hook("on_load", 50, function()
  key = mp.get_property("path")
  local pos = load_state()[key]
  if pos then
    mp.set_property("file-local-options/start", tostring(pos))
    print(("resuming at %.2f"):format(pos))
  else
    print("no saved position")
  end
end)

local restarts = 0
mp.register_event("playback-restart", function()
  restarts = restarts + 1
  print(("playing from %.2f"):format(mp.get_property_number("time-pos")))
  if restarts == 1 and opts.demo_seek >= 0 then
    mp.commandv("seek", tostring(opts.demo_seek), "absolute+exact")
  else
    mp.command("quit")
  end
end)

-- on_unload runs while properties of the old file are still readable
mp.add_hook("on_unload", 50, function()
  local pos = mp.get_property_number("time-pos") or 0
  local state = load_state()
  if pos >= opts.min_position then state[key] = pos else state[key] = nil end
  save_state(state)
  print(("saved %.2f"):format(pos))
end)
