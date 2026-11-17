-- while_repeat.lua: pre-tested and post-tested loops
local n, steps = 27, 0
while n ~= 1 do                    -- Collatz: test before each iteration
  if n % 2 == 0 then n = math.floor(n / 2) else n = 3 * n + 1 end
  steps = steps + 1
end
print("collatz(27) steps:", steps)

-- repeat ... until: body runs at least once, and the condition can see
-- locals declared inside the body (unlike C's do/while)
local attempts = 0
repeat
  attempts = attempts + 1
  local done = attempts * attempts > 50
until done
print("attempts:", attempts)
