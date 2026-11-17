-- tables.lua: ways to append to an array
local bench = require("bench")
local N = 1000000

local function check(t) return #t + t[N] end

local cases = {
  { "table.insert(t, v)", function()
      local t = {}
      for i = 1, N do table.insert(t, i) end
      return check(t)
    end },
  { "t[#t + 1] = v", function()
      local t = {}
      for i = 1, N do t[#t + 1] = i end
      return check(t)
    end },
  { "t[i] = v", function()
      local t = {}
      for i = 1, N do t[i] = i end
      return check(t)
    end },
}
if table.create then                          -- Lua 5.5: preallocate the array part
  cases[#cases + 1] = { "table.create(N) + t[i] = v", function()
      local t = table.create(N)
      for i = 1, N do t[i] = i end
      return check(t)
    end }
end
bench.compare("array append", cases)
