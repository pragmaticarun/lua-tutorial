-- protect.lua: __metatable hides and locks a metatable; strings share one
local obj = setmetatable({}, { __metatable = "not your business" })
print(getmetatable(obj))
print(pcall(setmetatable, obj, {}))
print(getmetatable("abc").__index == string)   -- why s:upper() works
