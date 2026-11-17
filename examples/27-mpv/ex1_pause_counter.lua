-- host: mpv
-- Exercise 1: count how often playback was paused, using observe_property
-- (not polling), and print a summary at shutdown.
local pauses, last = 0, nil

mp.observe_property("pause", "bool", function(_, paused)
  if paused and last == false then pauses = pauses + 1 end
  last = paused
end)

mp.register_event("shutdown", function()
  print("paused " .. pauses .. " time(s)")
end)

mp.register_event("file-loaded", function()
  -- toggle five times, 50 ms apart: pause, play, pause, play, pause
  for i = 1, 5 do mp.add_timeout(0.05 * i, function() mp.command("cycle pause") end) end
  mp.add_timeout(0.35, function() mp.command("quit") end)
end)
