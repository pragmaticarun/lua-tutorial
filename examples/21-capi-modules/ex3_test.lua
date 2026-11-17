-- Exercise 3 test: map and try_map
local m = require("ex3_map")
print(table.concat(m.map({ 10, 20, 30 }, function(v, i) return v * i end), " "))
print(pcall(m.map, { 1, "x" }, function(v) return v + 1 end))
local ok, res = m.try_map({ 1, 2 }, function(v) return -v end)
print(ok, res[1], res[2])
local ok2, err = m.try_map({ 1 }, function() error({ code = 7 }) end)
print(ok2, type(err), err.code)               -- error objects pass through intact
