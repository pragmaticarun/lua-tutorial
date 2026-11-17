-- nul_pattern.lua: a NUL byte in a pattern, outside and inside a set
local data = "a\0b"
print(pcall(string.find, data, "\0"))
print(pcall(string.find, data, "[\0]"))
