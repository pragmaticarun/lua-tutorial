-- ephemeron.lua: weak-key tables whose values point back at their keys
local meta = setmetatable({}, { __mode = "k" })

do
  local obj = {}
  meta[obj] = { owner = obj }   -- the value references the key
end                             -- obj is now unreachable from outside

collectgarbage(); collectgarbage()
local left = 0
for _ in pairs(meta) do left = left + 1 end
print("entries left:", left)
-- Lua 5.2+: 0. The table is an ephemeron table; a value only keeps its key
-- alive if the key is reachable from somewhere else.
-- LuaJIT (5.1 semantics): 1. The value is strong, so it keeps the key alive: a leak.
