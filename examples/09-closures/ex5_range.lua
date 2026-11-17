-- Exercise 5 solution: a closure-based iterator for the generic for
local function range(from, to, step)
  step = step or 1
  local i = from - step
  return function()
    i = i + step
    if (step > 0 and i <= to) or (step < 0 and i >= to) then return i end
  end
end
for i in range(1, 5) do io.write(i, " ") end print()
for i in range(10, 0, -4) do io.write(i, " ") end print()
