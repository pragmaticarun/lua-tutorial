-- random.lua: same seed, same sequence - but only within one implementation
math.randomseed(42)
local a = { math.random(1, 100), math.random(1, 100), math.random(1, 100) }
math.randomseed(42)
local b = { math.random(1, 100), math.random(1, 100), math.random(1, 100) }
print(table.concat(a, " "), table.concat(a, " ") == table.concat(b, " "))
local r = math.random()                         -- float in [0, 1)
print(r >= 0 and r < 1)
