-- targets: 5.5, 5.4
-- gc_modes.lua: switching between incremental and generational collection
-- Each call returns the PREVIOUS mode. The standalone `lua` program switches
-- to generational mode at start-up; an embedded lua_State starts incremental.
print("start-up mode:", collectgarbage("incremental"))
print("now:", collectgarbage("generational"))
print("now:", collectgarbage("incremental"))

-- A full collection works in either mode
local t = setmetatable({}, { __mode = "v" })
t[1] = {}
collectgarbage()
print("weak entry collected:", t[1] == nil)
