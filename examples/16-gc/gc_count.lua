-- gc_count.lua: watching the heap with collectgarbage("count")
collectgarbage()                                    -- start from a clean heap
local before = collectgarbage("count")              -- KiB in use, as a float
print(type(before), before > 0)

local keep = {}
for i = 1, 100000 do keep[i] = { i } end            -- ~100k small tables
local during = collectgarbage("count")
print("grew by more than 4 MiB:", during - before > 4096)

keep = nil                                          -- drop the only reference
collectgarbage()                                    -- full collection
local after = collectgarbage("count")
print("released most of it:", after - before < 512)
print("collector running:", collectgarbage("isrunning"))
