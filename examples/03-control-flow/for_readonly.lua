-- for_readonly.lua: may the loop body assign the control variable?
local src = [[
  local out = {}
  for i = 1, 3 do
    i = i * 10                 -- assign to the control variable
    out[#out + 1] = i
  end
  return table.concat(out, " ")
]]
local fn, err = load(src, "=loop")
if fn then
  print("compiled; result:", fn())
else
  print("compile error:", err)
end
