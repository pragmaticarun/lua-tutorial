-- number_error.lua: does a numeric error value get a position prefix?
local ok, e = pcall(function() error(42) end)
print(ok, e, type(e))
