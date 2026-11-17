-- targets: 5.5
-- Exercise 3 solution: let the 5.5 compiler find the typo
local src = [[
global print, ipairs
local function average(xs)
  local total = 0
  for _, x in ipairs(xs) do total = total + x end
  return totl / #xs
end
print(average({ 1, 2, 3 }))
]]
print(load(src, "=average.lua"))
-- fixed version compiles and runs
local fixed = src:gsub("totl", "total")
load(fixed, "=average.lua")()
