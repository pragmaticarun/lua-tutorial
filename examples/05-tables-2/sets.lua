-- sets.lua: a set is a table whose keys are the members (values are true)
local function Set(list)
  local s = {}
  for _, v in ipairs(list) do s[v] = true end
  return s
end
local function union(a, b)
  local r = {}
  for k in pairs(a) do r[k] = true end
  for k in pairs(b) do r[k] = true end
  return r
end
local function intersection(a, b)
  local r = {}
  for k in pairs(a) do if b[k] then r[k] = true end end
  return r
end
local function show(s)              -- sort for deterministic output
  local items = {}
  for k in pairs(s) do items[#items + 1] = k end
  table.sort(items)
  return "{" .. table.concat(items, ", ") .. "}"
end

local hw = Set { "h264", "hevc", "vp9" }
local sw = Set { "av1", "h264", "vp9" }
print(hw.hevc, hw.av1)              -- O(1) membership test
print(show(union(hw, sw)))
print(show(intersection(hw, sw)))
