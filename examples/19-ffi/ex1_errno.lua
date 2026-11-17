-- targets: jit
-- Exercise 1 solution: C errors with ffi.errno() and strerror
local ffi = require("ffi")
ffi.cdef [[
  typedef struct FILE FILE;
  FILE *fopen(const char *path, const char *mode);
  int fclose(FILE *f);
  char *strerror(int errnum);
]]
local function c_open(path, mode)
  local f = ffi.C.fopen(path, mode)
  if f == nil then                        -- read errno right after the failing call
    local e = ffi.errno()
    return nil, ("%s: %s (errno %d)"):format(path, ffi.string(ffi.C.strerror(e)), e)
  end
  return ffi.gc(f, ffi.C.fclose)
end
print(c_open("/definitely/not/here.txt", "r"))
local f = assert(c_open("ex1_errno.lua", "r"))
print("opened:", f ~= nil)
