-- host: mpv
-- Events: mpv tells scripts what happens to playback. Each script runs in
-- its own Lua state and thread, and handlers run one at a time.
local function log(...) print(...) end   -- print() goes to mpv's log as "[events] ..."

log("script name:", mp.get_script_name())

for _, name in ipairs({ "start-file", "file-loaded", "playback-restart", "seek", "end-file", "shutdown" }) do
  mp.register_event(name, function(ev)
    local extra = ev.reason and (" reason=" .. ev.reason) or ""
    log("event " .. ev.event .. extra)
  end)
end

-- after the first playback-restart, seek once; quit at the next restart
local restarts = 0
mp.register_event("playback-restart", function()
  restarts = restarts + 1
  if restarts == 1 then
    mp.commandv("seek", "1", "absolute", "exact")
  elseif restarts == 2 then
    -- a generated (lavfi) stream lands on a frame near 1 s, not exactly on it
    local pos = mp.get_property_number("time-pos")
    log("position after seek is within 0.2 s of 1.0:", math.abs(pos - 1) < 0.2)
    mp.command("quit 4")                -- exit code 4 for the test
  end
end)
