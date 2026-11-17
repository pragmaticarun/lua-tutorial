-- targets: jit
-- Exercise 2 solution: a vec3 type with operators and methods via ffi.metatype
local ffi = require("ffi")
local vec3
local methods = {
  dot = function(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end,
  normalized = function(a) local l = #a; return vec3(a.x / l, a.y / l, a.z / l) end,
}
vec3 = ffi.metatype("struct { float x, y, z; }", {
  __add = function(a, b) return vec3(a.x + b.x, a.y + b.y, a.z + b.z) end,
  __mul = function(a, k) return vec3(a.x * k, a.y * k, a.z * k) end,
  __len = function(a) return math.sqrt(a:dot(a)) end,
  __eq = function(a, b) return a.x == b.x and a.y == b.y and a.z == b.z end,
  __tostring = function(a) return ("(%g, %g, %g)"):format(a.x, a.y, a.z) end,
  __index = methods,
})
local a, b = vec3(1, 2, 2), vec3(2, 0, 0)
print(tostring(a + b), tostring(a * 2), #a, a:dot(b))
print(tostring(b:normalized()), a == vec3(1, 2, 2), ffi.sizeof(a))
