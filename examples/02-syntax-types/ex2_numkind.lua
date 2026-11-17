-- Exercise 2 solution: portable number classification
local function numkind(x)
  if type(x) ~= "number" then return "not a number" end
  if math.type then return math.type(x) end         -- Lua 5.3+
  -- LuaJIT / 5.1: only doubles; report integral values specially
  if x == math.floor(x) then return "integral float" end
  return "float"
end
for _, v in ipairs({ 42, 42.0, 2.5, "42" }) do
  print(tostring(v), numkind(v))
end
