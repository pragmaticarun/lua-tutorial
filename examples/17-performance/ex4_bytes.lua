-- Exercise 4 solution: scanning bytes of a 1 MB string
local bench = require("bench")
local data = string.rep("\0\1\2\3\4\5\6\7", 131072)   -- 1 MiB

bench.compare("ex4 byte checksum", {
  { "s:sub(i, i):byte()", function()
      local sum = 0
      for i = 1, #data do sum = sum + data:sub(i, i):byte() end
      return sum
    end },
  { "s:byte(i)", function()
      local sum, byte = 0, string.byte
      for i = 1, #data do sum = sum + byte(data, i) end
      return sum
    end },
  { "s:byte(i, i + 7), 8 at a time", function()
      local sum, byte = 0, string.byte
      for i = 1, #data, 8 do
        local a, b, c, d, e, f, g, h = byte(data, i, i + 7)
        sum = sum + a + b + c + d + e + f + g + h
      end
      return sum
    end },
})
