-- Exercise 2 solution: a printf-style logger with a level filter
local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }
local threshold = LEVELS.info
local function log(level, fmt, ...)
  if LEVELS[level] < threshold then return end
  print(string.format("[%-5s] " .. fmt, level:upper(), ...))
end
log("debug", "not shown %d", 1)
log("info", "opened %s (%dx%d)", "clip.mp4", 1920, 1080)
log("warn", "dropped %d frames", 3)
log("error", "%s", "device lost")
