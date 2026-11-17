-- targets: jit
-- trace_log.lua: the same output as `luajit -jv`, captured from inside a script
local tmp = os.tmpname()
require("jit.v").on(tmp)

local s = 0
for i = 1, 1000 do s = s + i end                      -- 1. a simple hot loop

local t = {}
for i = 1, 1000 do t[i] = tostring(i) end             -- 2. calls a C function

local fs = {}
for i = 1, 1000 do fs[i] = function() return i end end -- 3. creates closures

for i = 1, 1000 do                                    -- 4. a branch taken half the time
  if i % 2 == 0 then s = s + 1 else s = s - 1 end
end

require("jit.v").off()
for line in io.lines(tmp) do print((line:gsub("%s+$", ""))) end
os.remove(tmp)
