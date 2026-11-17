-- targets: jit
-- finalizers_jit.lua: LuaJIT ignores __gc on tables; use userdata or cdata
local ignored = setmetatable({}, { __gc = function() print("never") end })
ignored = nil
collectgarbage()
print("table __gc ignored")

-- newproxy(true) creates an empty userdata with a fresh metatable (5.1 only)
local p = newproxy(true)
getmetatable(p).__gc = function() print("proxy finalized") end
p = nil
collectgarbage()

-- ffi.gc attaches a finalizer to a cdata object, ideal for C resources
local ffi = require("ffi")
ffi.cdef [[ void *malloc(size_t n); void free(void *p); ]]
local freed = 0
local buf = ffi.gc(ffi.C.malloc(1024), function(ptr) ffi.C.free(ptr); freed = freed + 1 end)
buf = nil
collectgarbage()
print("freed buffers:", freed)
