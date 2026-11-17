-- host: mpv
-- Exercise 4: a "position / duration (percent)" OSD line, formatted in Lua
-- and compared with mpv's own property expansion.
-- mpv's Lua is 5.1 or LuaJIT: no // operator, use math.floor
local function hms(t)
  t = math.floor(t + 0.5)
  return ("%02d:%02d:%02d"):format(math.floor(t / 3600), math.floor(t % 3600 / 60), t % 60)
end

local function clock_text()
  local pos = mp.get_property_number("time-pos", 0)
  local dur = mp.get_property_number("duration", 0)
  local pct = dur > 0 and pos / dur * 100 or 0
  -- %d would truncate 75.7 to 75; mpv rounds, so round too
  return ("%s / %s (%d%%)"):format(hms(pos), hms(dur), math.floor(pct + 0.5))
end

mp.register_event("playback-restart", function()
  local pos = mp.get_property_number("time-pos")
  if pos < 1 then mp.commandv("seek", "75", "absolute+exact"); return end
  print("lua:  " .. clock_text())
  print("mpv:  " .. mp.command_native({ "expand-text", "${time-pos} / ${duration} (${percent-pos}%)" }))
  mp.osd_message(clock_text(), 1)
  mp.command("quit")
end)
