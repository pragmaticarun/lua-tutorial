-- strings.lua: building a big string
local bench = require("bench")
local N = 20000

bench.compare("string building", {
  { "s = s .. x in a loop", function()
      local s = ""
      for i = 1, N do s = s .. i .. "," end   -- O(n^2): copies s every time
      return #s
    end },
  { "table + table.concat", function()
      local parts = {}
      for i = 1, N do parts[#parts + 1] = i .. "," end
      return #table.concat(parts)
    end },
  { "buffer with counter", function()
      local parts, n = {}, 0
      for i = 1, N do n = n + 1; parts[n] = i; n = n + 1; parts[n] = "," end
      return #table.concat(parts)
    end },
})
