-- le_fallback.lua: does '<=' fall back to __lt when __le is missing?
local mt = { __lt = function(a, b) return a.v < b.v end }
local a = setmetatable({ v = 1 }, mt)
local b = setmetatable({ v = 2 }, mt)
print("a < b ", a < b)
print("a <= b", pcall(function() return a <= b end))
