-- Exercise 3 solution: one function, three results
local function stats(...)
  local n = select("#", ...)
  if n == 0 then return nil, "no values" end
  local lo, hi, sum = math.huge, -math.huge, 0
  for i = 1, n do
    local v = select(i, ...)
    lo, hi, sum = math.min(lo, v), math.max(hi, v), sum + v
  end
  return lo, hi, sum / n
end
print(string.format("%g %g %g", stats(3, 9, 6)))
print(stats())
local lo, _, avg = stats(16.7, 33.3, 16.6)   -- '_' by convention: ignored
print(string.format("min %.1f avg %.1f", lo, avg))
