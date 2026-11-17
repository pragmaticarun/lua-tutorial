-- Exercise 3 solution: a Comparable mixin built on one compare() method
local Comparable = {
  __eq = function(a, b) return a:compare(b) == 0 end,
  __lt = function(a, b) return a:compare(b) < 0 end,
  __le = function(a, b) return a:compare(b) <= 0 end,   -- define it: 5.5 needs it
}
local Version = {}
Version.__index = Version
for k, v in pairs(Comparable) do Version[k] = v end
function Version.parse(s)
  local a, b, c = s:match("^(%d+)%.(%d+)%.(%d+)$")
  return setmetatable({ tonumber(a), tonumber(b), tonumber(c), s = s }, Version)
end
function Version:compare(o)
  for i = 1, 3 do
    if self[i] ~= o[i] then return self[i] < o[i] and -1 or 1 end
  end
  return 0
end
local v54, v55, v551 = Version.parse("5.4.9"), Version.parse("5.5.0"), Version.parse("5.5.1")
print(v54 < v55, v55 <= v551, v551 > v55, v55 == Version.parse("5.5.0"))
local list = { v551, v54, v55 }
table.sort(list)                                         -- uses __lt
for i, v in ipairs(list) do list[i] = v.s end
print(table.concat(list, " < "))
