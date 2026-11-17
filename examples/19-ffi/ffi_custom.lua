-- targets: jit
-- ffi_custom.lua: load our own shared library (media.c) and manage its objects
local ffi = require("ffi")
ffi.cdef [[
  typedef struct { int width, height; uint8_t *data; } frame_t;
  int media_version(void);
  int media_live_frames(void);
  frame_t *frame_new(int width, int height);
  void frame_free(frame_t *f);
  void frame_gradient(frame_t *f);
  uint32_t frame_checksum(const frame_t *f);
]]
local media = ffi.load("./build/libmedia.so")   -- a path, or a name like "media"

local v = media.media_version()
print(("libmedia %d.%d.%d"):format(math.floor(v / 10000), math.floor(v / 100) % 100, v % 100))

-- ffi.gc ties the C object's lifetime to the cdata: frame_free runs on collection
local function Frame(w, h)
  local f = media.frame_new(w, h)
  assert(f ~= nil, "out of memory")             -- NULL pointers compare equal to nil
  return ffi.gc(f, media.frame_free)
end

local f = Frame(320, 240)
media.frame_gradient(f)
print(f.width, f.height, f.data[0], f.data[321], media.frame_checksum(f))
print("live frames:", media.media_live_frames())

f = nil
collectgarbage()
print("after collect:", media.media_live_frames())

-- explicit early release: free now and disarm the finalizer
local g = Frame(16, 16)
media.frame_free(ffi.gc(g, nil))
print("after explicit free:", media.media_live_frames())
