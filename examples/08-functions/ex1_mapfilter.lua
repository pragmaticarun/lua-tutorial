-- Exercise 1 solution: map, filter and reduce
local function map(t, f) local r = {} for i, v in ipairs(t) do r[i] = f(v) end return r end
local function filter(t, p)
  local r = {}
  for _, v in ipairs(t) do if p(v) then r[#r + 1] = v end end
  return r
end
local function reduce(t, f, acc)
  for _, v in ipairs(t) do acc = f(acc, v) end
  return acc
end
local durations = { 12, 95, 3, 240, 61 }               -- seconds
local long = filter(durations, function(s) return s >= 60 end)
local minutes = map(long, function(s) return string.format("%d:%02d", math.floor(s / 60), s % 60) end)
print(table.concat(minutes, " "))
print("total", reduce(durations, function(a, b) return a + b end, 0))
