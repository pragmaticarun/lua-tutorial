-- keyword_global.lua: is 'global' still usable as a name?
local fn, err = load("local global = 1; return global", "=demo")
if fn then print("'global' is a name, value", fn()) else print(err) end
