-- targets: jit
-- ffi_libc.lua: call C library functions without writing any binding code
local ffi = require("ffi")

ffi.cdef [[
  size_t strlen(const char *s);
  int abs(int x);
  long strtol(const char *nptr, char **endptr, int base);
  int snprintf(char *buf, size_t size, const char *fmt, ...);
  double sqrt(double x);
]]
local C = ffi.C                         -- the default C namespace (libc, libm, ...)

print(C.strlen("hello"), type(C.strlen("hello")))   -- size_t comes back as uint64 cdata
print(tonumber(C.strlen("hello")), C.abs(-42), C.sqrt(2))

-- out-parameters: allocate a char* slot and pass its address
local endp = ffi.new("char *[1]")
local n = C.strtol("0x1F rest", endp, 16)
print(n, ffi.string(endp[0]))            -- converted part, then the remainder

-- a C buffer, filled by snprintf, copied into a Lua string with ffi.string
local buf = ffi.new("char[64]")
local len = C.snprintf(buf, 64, "%s=%d (%.2f)", "fps", ffi.new("int", 30), 29.97)
print(len, ffi.string(buf, len))
