-- targets: 5.5, 5.4
-- numbers.lua: one "number" type, two subtypes (integer and float)
print(3, 3.0, math.type(3), math.type(3.0))
print(10 / 2, 7 // 2, 7.0 // 2, -7 // 2)  -- '/' is always float; '//' floors
print(2^3, 7 % 3, -7 % 3)                 -- '^' is always float; '%' follows floor
print(1 == 1.0, math.tointeger(3.0), math.tointeger(3.5))
print(math.maxinteger, math.maxinteger + 1 == math.mininteger) -- wraps around
print(2^53 == 2^53 + 1, math.maxinteger + 0.0)  -- floats lose precision
print(pcall(function() return 1 // 0 end))   -- integer division by zero: error
print(1 / 0, -1 // 0.0)                      -- float division by zero: inf
print("10" + 1, "3.0" + 1, 10 .. 20)         -- string <-> number coercions
