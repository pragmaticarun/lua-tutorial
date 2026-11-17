-- Exercise 5 solution: a portable, seedable PRNG (same output on every Lua)
-- Park-Miller "minimal standard" generator; all values stay below 2^53.
local function prng(seed)
  local state = seed % 2147483647
  if state <= 0 then state = state + 2147483646 end
  return function(lo, hi)
    state = (state * 16807) % 2147483647
    return lo + state % (hi - lo + 1)
  end
end
local function shuffle(list, rand)
  for i = #list, 2, -1 do
    local j = rand(1, i)
    list[i], list[j] = list[j], list[i]
  end
  return list
end
local rand = prng(42)
print(rand(1, 100), rand(1, 100), rand(1, 100))
print(table.concat(shuffle({ "a", "b", "c", "d", "e" }, prng(7)), " "))
