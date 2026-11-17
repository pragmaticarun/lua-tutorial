-- strlib.lua: the most-used string functions
local s = "Hello, Lua World"
print(s:len(), s:lower(), s:upper())
print(s:sub(1, 5), s:sub(8), s:sub(-5), s:sub(-5, -3))   -- 1-based, inclusive, negative from end
print(s:rep(2, " / "))
print(s:reverse())
print(s:byte(1), s:byte(-1), string.char(76, 117, 97))  -- bytes <-> chars
print(s:find("Lua"))                    -- start and end indices
print(s:find("o", 6))                   -- search from position 6
print(s:find(".", 1, true))             -- plain=true: no pattern magic (no match -> nil)
print(s:find(","))
