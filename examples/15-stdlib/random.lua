-- random.lua: same seed, same sequence - but only within one implementation
math.randomseed(42)
local a = { math.random(1, 100), math.random(1, 100), math.random(1, 100) }
math.randomseed(42)
local b = { math.random(1, 100), math.random(1, 100), math.random(1, 100) }
local same = table.concat(a, " ") == table.concat(b, " ")
if jit then
  -- LuaJIT's values for seed 42 even differed between two x86-64 machines
  -- running the same LuaJIT commit, so they are not printed here.
  print("LuaJIT sequence not shown", same)
else
  print(table.concat(a, " "), same)
end
local r = math.random()                         -- float in [0, 1)
print(r >= 0 and r < 1)
