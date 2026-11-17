-- use_vec.lua: using the C module from vec.c
local vec = require("vec")
local a, b = vec.new(3, 4), vec.new(1, 1)
print(type(a), a:len(), a:unpack())
print(tostring(a + b), a + b == vec.new(4, 5))
print(pcall(a.len, 42))                     -- luaL_checkudata rejects non-vectors
print(pcall(function() return a + 1 end))
-- the metatable is in the registry under the name given to luaL_newmetatable
print(getmetatable(a) == debug.getregistry()["tutorial.Vec2"])
