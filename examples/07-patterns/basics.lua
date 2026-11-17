-- basics.lua: the four pattern functions and the main building blocks
local line = "2026-11-16 12:53:07 WARN decoder: dropped 3 frames (pts=90000)"

print(line:find("WARN"))                 -- start, end
print(line:match("%d+"))                 -- first run of digits
print(line:match("^(%d+)-(%d+)-(%d+)"))  -- anchored, three captures
print(line:match("%u+"))                 -- first run of upper-case letters
print(line:match("dropped (%d+) frames"))
print(line:match("%((.-)%)"))            -- %( escapes '(', .- is lazy
print(line:match("%b()"))                -- balanced parentheses
print(line:match("(%a+)$"))              -- nil: line ends with ')'

for word in line:gmatch("%a+") do io.write(word, " ") end
print()
print(line:gsub("%d", "#"))              -- new string, and count of replacements
