-- Exercise 3 solution: count calls per function with a "call" hook
local function decode() end
local function scale() end
local function encode() decode(); scale() end

local counts = {}
debug.sethook(function()
  local info = debug.getinfo(2, "nS")
  if info.what == "Lua" and info.name then
    counts[info.name] = (counts[info.name] or 0) + 1
  end
end, "c")
for _ = 1, 3 do encode() end
decode()
debug.sethook()

local names = {}
for k in pairs(counts) do names[#names + 1] = k end
table.sort(names)
for _, k in ipairs(names) do print(k, counts[k]) end
