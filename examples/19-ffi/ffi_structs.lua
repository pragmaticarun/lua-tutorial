-- targets: jit
-- ffi_structs.lua: C structs, arrays, pointers and metatypes
local ffi = require("ffi")
ffi.cdef [[
  typedef struct { int16_t x, y; } point_t;
  typedef struct { point_t origin; uint16_t width, height; uint8_t flags; } rect_t;
]]

print(ffi.sizeof("point_t"), ffi.sizeof("rect_t"), ffi.offsetof("rect_t", "flags"),
      ffi.alignof("rect_t"))

local r = ffi.new("rect_t", { { 10, 20 }, 640, 480, 1 })   -- nested initialisers
print(r.origin.x, r.origin.y, r.width * r.height, r.flags)
r.width = 70000                                -- C semantics: uint16_t wraps around
print(r.width)

-- arrays are 0-based and fixed size; [?] takes the length at run time
local pts = ffi.new("point_t[?]", 3, { { 1, 2 }, { 3, 4 }, { 5, 6 } })
local sum = 0
for i = 0, 2 do sum = sum + pts[i].x + pts[i].y end
print(ffi.sizeof(pts), sum)
local p = pts + 1                               -- pointer arithmetic
print(p.x, p[1].y, ffi.istype("point_t *", p))

-- metatype: methods and operators for a C type, like a class
local vec2
vec2 = ffi.metatype("struct { double x, y; }", {
  __add = function(a, b) return vec2(a.x + b.x, a.y + b.y) end,
  __tostring = function(v) return ("vec2(%g, %g)"):format(v.x, v.y) end,
  __index = { len = function(v) return math.sqrt(v.x * v.x + v.y * v.y) end },
})
local v = vec2(3, 4) + vec2(0, 0)
print(tostring(v), v:len())

-- 64-bit integers: the LL / ULL suffixes create int64_t / uint64_t cdata
local big = 9007199254740993LL
print(big, big + 1, tostring(2^53 + 1), 0xFFFFFFFFFFFFFFFFULL)
