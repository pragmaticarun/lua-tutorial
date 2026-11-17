-- which_lua.lua: detect the interpreter at run time
local function describe()
  if type(jit) == "table" then
    return "LuaJIT (language level " .. _VERSION .. ")"
  end
  return "PUC-Rio " .. _VERSION
end

print(describe())
-- math.type only exists from Lua 5.3 on; LuaJIT has no integer subtype
print("has integer subtype:", math.type ~= nil)
