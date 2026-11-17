-- targets: 5.5, 5.4
-- const_local.lua: <const> locals (Lua 5.4+) are checked at compile time
local MAX <const> = 3
print("MAX is", MAX)
local fn, err = load("local LIMIT <const> = 10; LIMIT = 11", "=demo")
print(fn, err)
