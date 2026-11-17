-- Exercise 1 solution: FizzBuzz with if/elseif
local out = {}
for i = 1, 15 do
  local s
  if i % 15 == 0 then s = "FizzBuzz"
  elseif i % 3 == 0 then s = "Fizz"
  elseif i % 5 == 0 then s = "Buzz"
  else s = tostring(i) end
  out[#out + 1] = s
end
print(table.concat(out, " "))
