-- host: mpv
-- Exercise 2: [ and ] change speed in steps of 0.25 between 0.25 and 4,
-- showing the new speed on the OSD; Backspace resets it.
local MIN, MAX, STEP = 0.25, 4, 0.25

local function change(delta)
  local s = mp.get_property_number("speed") + delta
  s = math.max(MIN, math.min(MAX, s))
  mp.set_property_number("speed", s)
  mp.osd_message(("speed %.2fx"):format(s))
  print(("speed -> %.2f"):format(s))
end

mp.add_forced_key_binding("]", "faster", function() change(STEP) end, { repeatable = true })
mp.add_forced_key_binding("[", "slower", function() change(-STEP) end, { repeatable = true })
mp.add_forced_key_binding("BS", "reset", function()
  mp.set_property_number("speed", 1); print("speed reset")
end)

mp.register_event("file-loaded", function()
  local keys = { "]", "]", "[", "[", "[", "[", "[", "BS" }
  for i, k in ipairs(keys) do mp.add_timeout(0.03 * i, function() mp.commandv("keypress", k) end) end
  mp.add_timeout(0.03 * (#keys + 2), function() mp.command("quit") end)
end)
