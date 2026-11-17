-- iteration.lua: numeric for vs ipairs vs pairs over an array
local bench = require("bench")
local N = 1000000
local data = {}
for i = 1, N do data[i] = i % 7 end

bench.compare("array iteration", {
  { "for i = 1, #t", function()
      local s = 0
      for i = 1, #data do s = s + data[i] end
      return s
    end },
  { "ipairs", function()
      local s = 0
      for _, v in ipairs(data) do s = s + v end
      return s
    end },
  { "pairs", function()
      local s = 0
      for _, v in pairs(data) do s = s + v end
      return s
    end },
})
