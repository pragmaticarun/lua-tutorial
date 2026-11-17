-- stateful_iter.lua: closure iterators keep their own state
local function words(s)
  local pos = 1
  return function()
    local from, to = s:find("%S+", pos)
    if not from then return nil end
    pos = to + 1
    return s:sub(from, to), from
  end
end
for w, at in words("  decode  scale encode ") do print(at, w) end

local function sorted_pairs(t)              -- iterate a map in key order
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys)
  local i = 0
  return function()
    i = i + 1
    local k = keys[i]
    if k ~= nil then return k, t[k] end
  end
end
for k, v in sorted_pairs({ fps = 30, codec = "av1", bitrate = 4500 }) do print(k, v) end
