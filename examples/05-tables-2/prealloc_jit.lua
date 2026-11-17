-- targets: jit
-- prealloc_jit.lua: LuaJIT's equivalent is the table.new extension module
local new_tab = require("table.new")
local samples = new_tab(48000, 0)           -- (narray, nhash)
print(#samples)
for i = 1, 48000 do samples[i] = 0 end
print(#samples)
local clear = require("table.clear")        -- empty a table, keep its capacity
clear(samples)
print(#samples)
