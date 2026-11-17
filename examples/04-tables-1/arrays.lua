-- arrays.lua: a table with keys 1..n is Lua's array (a "sequence")
local frames = { "I", "P", "B", "B", "P" }   -- constructor: keys 1..5
print(frames[1], frames[5], frames[6])         -- indices start at 1; missing -> nil
print("length:", #frames)

frames[#frames + 1] = "I"                      -- append idiom
table.insert(frames, "P")                      -- same, via the library
table.insert(frames, 1, "IDR")                 -- insert at position 1 (shifts up)
print(table.concat(frames, ","), #frames)

local last = table.remove(frames)              -- pop from the end
local first = table.remove(frames, 1)          -- remove at position 1 (shifts down)
print(first, last, table.concat(frames, ","))

for i = #frames, 1, -1 do io.write(frames[i], " ") end   -- reverse walk
print()
