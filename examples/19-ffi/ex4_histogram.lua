-- targets: jit
-- Exercise 4 solution: pass a cdata array to C and check the result in Lua
local ffi = require("ffi")
ffi.cdef [[
  typedef struct { int width, height; uint8_t *data; } frame_t;
  frame_t *frame_new(int width, int height);
  void frame_free(frame_t *f);
  void frame_gradient(frame_t *f);
  void frame_histogram(const frame_t *f, uint32_t bins[256]);
]]
local media = ffi.load("./build/libmedia.so")
local f = ffi.gc(media.frame_new(300, 200), media.frame_free)
media.frame_gradient(f)

local bins = ffi.new("uint32_t[256]")          -- arrays decay to pointers, as in C
media.frame_histogram(f, bins)

local lua_bins = {}
for i = 0, f.width * f.height - 1 do
  local v = f.data[i]
  lua_bins[v] = (lua_bins[v] or 0) + 1
end
local same = true
for v = 0, 255 do if bins[v] ~= (lua_bins[v] or 0) then same = false end end
print("bin 0:", bins[0], "bin 255:", bins[255], "bin 299 mod 256:", bins[299 % 256])
print("C and Lua agree:", same)
