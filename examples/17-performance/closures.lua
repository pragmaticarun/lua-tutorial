-- closures.lua: creating a closure per iteration vs hoisting it
local bench = require("bench")
local N = 300000
local items = {}
for i = 1, 8 do items[i] = i end

local function sum_with(t, f)
  local s = 0
  for i = 1, #t do s = s + f(t[i]) end
  return s
end

bench.compare("closures in loops", {
  { "new closure each iteration", function()
      local total = 0
      for k = 1, N do
        total = total + sum_with(items, function(x) return x * 2 end)
      end
      return total
    end },
  { "closure hoisted out of the loop", function()
      local total = 0
      local double = function(x) return x * 2 end
      for k = 1, N do total = total + sum_with(items, double) end
      return total
    end },
})
