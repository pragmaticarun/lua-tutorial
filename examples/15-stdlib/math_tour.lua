-- math_tour.lua: the math library
print(math.floor(3.7), math.ceil(3.2), math.floor(-3.5))
print(math.abs(-4), math.max(3, 9, 1), math.min(2.5, -1))
print(math.sqrt(2), math.pi, math.huge, -math.huge)
print(math.fmod(7, 3), math.fmod(-7, 3), -7 % 3)   -- fmod truncates, % floors
local ip, fp = math.modf(3.75)
print(ip, fp)
print(math.exp(0), math.log(8, 2), math.log(100, 10), math.sin(0))
print(math.huge > 1e308, -math.huge < -1e308)
