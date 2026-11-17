-- Exercise 3 solution: complex numbers with operators
local C = {}
C.__index = C
local function complex(re, im) return setmetatable({ re = re, im = im or 0 }, C) end
local function lift(v) if type(v) == "number" then return complex(v) end return v end
C.__add = function(a, b) a, b = lift(a), lift(b); return complex(a.re + b.re, a.im + b.im) end
C.__mul = function(a, b)
  a, b = lift(a), lift(b)
  return complex(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re)
end
C.__eq = function(a, b) return a.re == b.re and a.im == b.im end
C.__tostring = function(a)
  return string.format("%g%+gi", a.re, a.im)
end
local i = complex(0, 1)
print(tostring(i * i), tostring(1 + i), tostring((1 + i) * (1 + i)))
print(i * i == complex(-1, 0))
