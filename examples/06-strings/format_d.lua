-- format_d.lua: %d with a fractional number
print(pcall(string.format, "%d", 3.0))    -- integral float: fine everywhere
print(pcall(string.format, "%d", 2.5))    -- fractional: depends on the version
