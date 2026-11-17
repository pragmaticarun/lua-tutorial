-- targets: jit
-- ffi_perf.lua: plain Lua tables vs FFI cdata, measured with Lesson 17's harness
package.path = "../17-performance/?.lua;" .. package.path
local bench = require("bench")
local ffi = require("ffi")
ffi.cdef [[ typedef struct { double x, y; } pt_t; double sqrt(double); ]]

local N = 1000000
bench.compare("sum 1M doubles", {
  { "Lua table", function()
      local t = {}
      for i = 1, N do t[i] = i * 0.5 end
      local s = 0
      for i = 1, N do s = s + t[i] end
      return s
    end },
  { "FFI double[N]", function()
      local a = ffi.new("double[?]", N + 1)
      for i = 1, N do a[i] = i * 0.5 end
      local s = 0
      for i = 1, N do s = s + a[i] end
      return s
    end },
})

local W, H = 640, 480
bench.compare("RGB to grey, 640x480", {
  { "Lua table of bytes", function()
      local rgb, grey = {}, {}
      for i = 1, W * H * 3 do rgb[i] = i % 256 end
      local sum = 0
      for p = 0, W * H - 1 do
        local r, g, b = rgb[p * 3 + 1], rgb[p * 3 + 2], rgb[p * 3 + 3]
        local y = math.floor((77 * r + 150 * g + 29 * b) / 256)
        grey[p + 1] = y; sum = sum + y
      end
      return sum
    end },
  { "FFI uint8_t buffers", function()
      local rgb = ffi.new("uint8_t[?]", W * H * 3)
      local grey = ffi.new("uint8_t[?]", W * H)
      for i = 0, W * H * 3 - 1 do rgb[i] = (i + 1) % 256 end
      local sum = 0
      for p = 0, W * H - 1 do
        local r, g, b = rgb[p * 3], rgb[p * 3 + 1], rgb[p * 3 + 2]
        local y = bit.rshift(77 * r + 150 * g + 29 * b, 8)
        grey[p] = y; sum = sum + y
      end
      return sum
    end },
})

local M = 200000
bench.compare("array of 200k points", {
  { "table of tables", function()
      local pts = {}
      for i = 1, M do pts[i] = { x = i, y = -i } end
      local s = 0
      for i = 1, M do local p = pts[i]; s = s + p.x - p.y end
      return s
    end },
  { "FFI pt_t[M]", function()
      local pts = ffi.new("pt_t[?]", M + 1)
      for i = 1, M do pts[i].x = i; pts[i].y = -i end
      local s = 0
      for i = 1, M do local p = pts[i]; s = s + p.x - p.y end
      return s
    end },
})

bench.compare("1M square roots", {
  { "math.sqrt", function()
      local s, sqrt = 0, math.sqrt
      for i = 1, N do s = s + sqrt(i) end
      return math.floor(s)
    end },
  { "ffi.C.sqrt", function()
      local s, sqrt = 0, ffi.C.sqrt
      for i = 1, N do s = s + sqrt(i) end
      return math.floor(s)
    end },
})
