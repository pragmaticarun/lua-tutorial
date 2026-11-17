-- targets: jit
-- Exercise 3 solution: which IR instructions in a trace are guards?
local tmp = os.tmpname()
local data = {}
for i = 1, 500 do data[i] = i * 0.5 end

require("jit.dump").on("i", tmp)
local s = 0
for i = 1, #data do s = s + data[i] end
require("jit.dump").off()

local guards = {}
for line in io.lines(tmp) do
  local op = line:match("^%d+ >%s+%a+ (%u+)")   -- "0004 >  num SLOAD ..." is a guard
  if op then guards[#guards + 1] = op end
end
os.remove(tmp)
print(#guards .. " guards: " .. table.concat(guards, " "))
print(s)
