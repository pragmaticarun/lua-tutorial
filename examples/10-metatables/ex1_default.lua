-- Exercise 1 solution: a table that returns a default for missing keys
local function with_default(default)
  return setmetatable({}, { __index = function() return default end })
end
local counts = with_default(0)
for word in ("a b a c a b"):gmatch("%a") do counts[word] = counts[word] + 1 end
print(counts.a, counts.b, counts.c, counts.z)
