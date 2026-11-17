-- errors.lua: errors inside coroutines
local co = coroutine.create(function() error({ code = 7 }) end)
local ok, e = coroutine.resume(co)            -- resume catches like pcall
print(ok, type(e), e.code, coroutine.status(co))

local gen = coroutine.wrap(function() error("boom", 0) end)
print(pcall(gen))                            -- wrap re-raises in the caller

-- yield works across pcall (Lua 5.2+ and LuaJIT)...
local c2 = coroutine.create(function()
  local ok2, v = pcall(function() return coroutine.yield("from inside pcall") end)
  return ok2, v
end)
print(coroutine.resume(c2))
print(coroutine.resume(c2, "resumed"))

-- ...but not across a C function such as table.sort's comparator
local c3 = coroutine.wrap(function()
  table.sort({ 3, 1, 2 }, function(a, b) coroutine.yield(); return a < b end)
end)
print(pcall(c3))
