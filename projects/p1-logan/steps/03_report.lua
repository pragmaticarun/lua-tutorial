-- Step 3: aggregate a whole file. report.add takes nil for lines that did
-- not parse, so the counting code never needs to know why.
package.path = "../src/?.lua;../src/?/init.lua;" .. package.path
local parse = require("logan.parse")
local report = require("logan.report")

local st, n = report.new(), 0
for line in io.lines("../data/access.log") do
  n = n + 1
  report.add(st, parse.line(line), "access.log:" .. n)
end
print(report.text(st, 3))
