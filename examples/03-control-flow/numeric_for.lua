-- numeric_for.lua: for var = start, limit [, step]
for i = 1, 3 do io.write(i, " ") end print()
for i = 10, 1, -3 do io.write(i, " ") end print()
for i = 1, 0 do print("never runs") end

-- start, limit and step are evaluated once, before the loop starts
local limit = 3
for i = 1, limit do
  limit = 10           -- has no effect on the running loop
  io.write(i, " ")
end
print()

-- the control variable is a fresh local, gone after the loop
local i = "outer"
for i = 1, 2 do end
print("i after loop:", i)
