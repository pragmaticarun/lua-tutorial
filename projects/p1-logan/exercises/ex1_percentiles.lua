-- Exercise 1 (solution): p50 and p95 of the "(took Nms)" durations in the
-- app log, nearest-rank method: the value at rank ceil(p/100 * n).
package.path = "../src/?.lua;../src/?/init.lua;" .. package.path
local parse = require("logan.parse")

local function percentile(sorted, p)
  if #sorted == 0 then return nil end
  return sorted[math.max(1, math.ceil(p / 100 * #sorted))]
end

local by_component = {}
for line in io.lines("../data/app.log") do
  local rec = parse.app(line)
  if rec and rec.ms then
    local list = by_component[rec.component] or {}
    by_component[rec.component] = list
    list[#list + 1] = rec.ms
  end
end

local names = {}
for name, list in pairs(by_component) do names[#names + 1] = name; table.sort(list) end
table.sort(names)
print(("%-12s %3s %6s %6s %6s"):format("component", "n", "p50", "p95", "max"))
for _, name in ipairs(names) do
  local l = by_component[name]
  print(("%-12s %3d %4dms %4dms %4dms"):format(name, #l, percentile(l, 50), percentile(l, 95), l[#l]))
end
