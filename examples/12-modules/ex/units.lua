-- module
-- ex/units.lua: Exercise 1 module - a public API with a private helper
local units = {}

local SUFFIXES = { "B", "KiB", "MiB", "GiB", "TiB" }  -- private
local function scale(n)                                -- private
  local i = 1
  while n >= 1024 and i < #SUFFIXES do n, i = n / 1024, i + 1 end
  return n, SUFFIXES[i]
end

function units.bytes(n)
  local v, suffix = scale(n)
  if suffix == "B" then return string.format("%d B", v) end
  return string.format("%.1f %s", v, suffix)
end

function units.bitrate(bits_per_second)
  return string.format("%.0f kb/s", bits_per_second / 1000)
end

return units
