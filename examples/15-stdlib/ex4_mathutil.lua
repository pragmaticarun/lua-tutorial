-- Exercise 4 solution: helpers missing from the math library
local function round(x)                       -- half away from zero
  if x >= 0 then return math.floor(x + 0.5) end
  return -math.floor(-x + 0.5)
end
local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
local function lerp(a, b, t) return a + (b - a) * t end
print(round(2.5), round(-2.5), round(2.4), round(-0.4) == 0)
print(clamp(130, 0, 100), clamp(-5, 0, 100), clamp(42, 0, 100))
print(("%g %g"):format(lerp(0, 1920, 0.25), lerp(10, 20, 0.5)))
