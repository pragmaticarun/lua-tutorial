-- tablelib.lua: the table library tour (portable subset)
local unpack = table.unpack or unpack       -- 5.1/LuaJIT: global unpack

local t = { 5, 2, 8, 1, 9 }
print(table.concat(t, "-"), table.concat(t, "", 2, 4))

table.sort(t)                               -- ascending, in place
print(table.concat(t, " "))
table.sort(t, function(a, b) return a > b end)  -- comparator: "a before b?"
print(table.concat(t, " "))

print(unpack({ "x", "y", "z" }))            -- table -> multiple values
local a, b = unpack({ 10, 20, 30 }, 2)      -- from index 2
print(a, b)

-- table.move(src, from, to, dest_start [, dest_table]): memmove for tables
local src, dst = { 1, 2, 3 }, { "a", "b", "c", "d" }
table.move(src, 1, 3, 2, dst)
print(table.concat(dst, " "))

-- sort records by a field
local clips = { { name = "b", dur = 3 }, { name = "a", dur = 7 }, { name = "c", dur = 1 } }
table.sort(clips, function(x, y) return x.dur < y.dur end)
for _, c in ipairs(clips) do io.write(c.name, ":", c.dur, " ") end
print()
