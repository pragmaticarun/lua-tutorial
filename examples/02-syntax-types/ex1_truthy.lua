-- Exercise 1 solution: classify values as truthy or falsy
-- an explicit n field keeps track of the length, so the nil is not lost
local values = { n = 6, nil, false, 0, "", "false", {} }
for i = 1, values.n do
  local v = values[i]
  local shown = tostring(v)
  if type(v) == "string" then shown = string.format("%q", v) end
  if type(v) == "table" then shown = "{}" end
  print(i, shown, v and "truthy" or "falsy")
end
