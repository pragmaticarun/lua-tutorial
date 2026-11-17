-- Exercise 2 solution: digit sum with a while loop (integer-safe everywhere)
local function digit_sum(n)
  local sum = 0
  while n > 0 do
    local d = n % 10
    sum = sum + d
    n = math.floor(n / 10)  -- stays an integer on 5.4/5.5 (math.floor returns one)
  end
  return sum
end
for _, n in ipairs({ 0, 7, 1234, 99999 }) do
  print(n, digit_sum(n))
end
