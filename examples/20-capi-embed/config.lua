-- module
-- config.lua: a configuration file read by call_lua.c (not an example on its own)
output = { width = 1280, height = 720, codec = "av1" }
presets = { "fast", "medium", "slow" }

function on_frame(n, pts)
  if n < 0 then error("negative frame number " .. n) end
  return n % 2 == 0 and "keyframe" or "delta", pts * 1000
end
