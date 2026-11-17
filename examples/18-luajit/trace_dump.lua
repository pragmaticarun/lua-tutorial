-- targets: jit
-- trace_dump.lua: bytecode and IR of one trace (like `luajit -jdump=bi`)
local tmp = os.tmpname()
require("jit.dump").on("bi", tmp)      -- b = bytecode, i = IR; add "m" for machine code

local s = 0
for i = 1, 1000 do s = s + i * 2 end

require("jit.dump").off()
for line in io.lines(tmp) do print((line:gsub("%s+$", ""))) end
os.remove(tmp)
print(s)
