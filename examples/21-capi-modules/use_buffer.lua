-- use_buffer.lua: deterministic close() first, __gc as the safety net
local buffer = require("buffer")

local a = buffer.new(1024):fill(2)
print(#a, a:sum(), buffer.stats())          -- live, closed, collected
a:close()
print(#a, pcall(a.sum, a))                  -- using a closed buffer is an error
a:close()                                   -- closing twice is harmless

do
  local forgotten = buffer.new(64)          -- never closed...
end
collectgarbage(); collectgarbage()          -- ...so the finalizer releases it
print(buffer.stats())
