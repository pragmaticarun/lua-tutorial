-- Exercise 2 solution: generate a CSV report without quadratic copying
local bench = require("bench")
local N = 5000

bench.compare("ex2 csv report", {
  { "slow: csv = csv .. line", function()
      local csv = "frame,pts,size\n"
      for i = 1, N do csv = csv .. i .. "," .. i * 40 .. "," .. (i * 37) % 9000 .. "\n" end
      return #csv
    end },
  { "fast: buffer + table.concat", function()
      local buf = { "frame,pts,size\n" }
      for i = 1, N do buf[#buf + 1] = i .. "," .. i * 40 .. "," .. (i * 37) % 9000 .. "\n" end
      return #table.concat(buf)
    end },
})
