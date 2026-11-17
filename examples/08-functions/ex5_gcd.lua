-- Exercise 5 solution: tail-recursive gcd and accumulator-style sum
local function gcd(a, b)
  if b == 0 then return a end
  return gcd(b, a % b)              -- tail call
end
local function sum_to(n, acc)
  acc = acc or 0
  if n == 0 then return acc end
  return sum_to(n - 1, acc + n)     -- tail call with accumulator
end
print(gcd(1920, 1080), gcd(48000, 44100))
print(sum_to(100), sum_to(2000000))
