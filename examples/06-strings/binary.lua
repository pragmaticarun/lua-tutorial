-- binary.lua: strings hold arbitrary bytes, including zeros
local blob = "RIFF\0\0\0\0WAVE"
print(#blob, blob:sub(9, 12), blob:byte(5))
-- a hex dump with string.byte + string.format
local hex = blob:gsub(".", function(c) return string.format("%02x ", c:byte()) end)
print(hex)
