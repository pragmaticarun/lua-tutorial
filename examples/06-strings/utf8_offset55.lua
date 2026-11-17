-- targets: 5.5
-- utf8_offset55.lua: in Lua 5.5, utf8.offset also returns the character's last byte
local s = "a☕b"
print(utf8.offset(s, 2))          -- start and end byte of the 2nd character
local i, j = utf8.offset(s, 2)
print(s:sub(i, j))
