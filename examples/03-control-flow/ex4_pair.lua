-- Exercise 4 solution: first pair summing to a target, using goto to exit both loops
local xs, target = { 3, 9, 14, 5, 11 }, 16
local a, b
for i = 1, #xs do
  for j = i + 1, #xs do
    if xs[i] + xs[j] == target then
      a, b = xs[i], xs[j]
      goto done
    end
  end
end
::done::
print(a and ("%d + %d = %d"):format(a, b, target) or "no pair")
