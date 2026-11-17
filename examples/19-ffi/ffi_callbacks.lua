-- targets: jit
-- ffi_callbacks.lua: C calling back into Lua
local ffi = require("ffi")
ffi.cdef [[
  void qsort(void *base, size_t n, size_t size, int (*cmp)(const void *, const void *));
  typedef struct { int width, height; uint8_t *data; } frame_t;
  typedef void (*row_cb)(int row, const uint8_t *pixels, int width, void *ud);
  frame_t *frame_new(int width, int height);
  void frame_free(frame_t *f);
  void frame_gradient(frame_t *f);
  void frame_foreach_row(const frame_t *f, row_cb cb, void *ud);
]]
local media = ffi.load("./build/libmedia.so")

-- 1. a Lua function passed where C expects a function pointer
local arr = ffi.new("int[6]", { 5, 3, 9, 1, 7, 2 })
local cmp = ffi.cast("int (*)(const void *, const void *)", function(a, b)
  local x, y = ffi.cast("const int *", a)[0], ffi.cast("const int *", b)[0]
  return x < y and -1 or (x > y and 1 or 0)
end)
ffi.C.qsort(arr, 6, ffi.sizeof("int"), cmp)
cmp:free()                         -- callbacks are a limited resource: free them
local out = {}
for i = 0, 5 do out[#out + 1] = arr[i] end
print(table.concat(out, " "))

-- 2. a callback with a row of pixels: sum each row in Lua
local f = ffi.gc(media.frame_new(4, 3), media.frame_free)
media.frame_gradient(f)
local sums = {}
local cb = ffi.cast("row_cb", function(row, pixels, width)
  local s = 0
  for x = 0, width - 1 do s = s + pixels[x] end
  sums[#sums + 1] = ("row %d: %d"):format(row, s)
end)
media.frame_foreach_row(f, cb, nil)
cb:free()
print(table.concat(sums, ", "))
