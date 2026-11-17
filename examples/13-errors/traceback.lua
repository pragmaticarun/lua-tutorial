-- traceback.lua: xpcall runs a handler BEFORE the stack unwinds
local function lvl3() error("deep failure") end
local function lvl2() lvl3() end
local function lvl1() lvl2() end

local ok, tb = xpcall(lvl1, debug.traceback)
print(ok)
print((tb:gsub("0x%x+", "ADDR")))              -- hide run-specific addresses

-- xpcall forwards extra arguments (Lua 5.2+ and LuaJIT)
print(xpcall(function(a, b) return a + b end, debug.traceback, 2, 3))
