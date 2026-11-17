-- The store without mpv: plain Lua, runs on Lua 5.5, 5.4 and LuaJIT.
package.path = "../bookmarks/?.lua;" .. package.path
local Store = require("store")

local s = Store.new()
print(s:add(125.25).title, s:add(2).title, s:add(61, "Demo starts").title)
local b, new = s:add(61.3)                 -- within 0.5 s of "Demo starts"
print("61.3 ->", b.title, new and "new" or "moved")
for _, line in ipairs(s:lines(60)) do print(line) end
print("next after 2.1:", s:next_after(2.1).title)
print("next after 2.0:", s:next_after(2.0).title, "(skips the one we are on)")
print("prev before 2.0:", tostring(s:prev_before(2.0)))
print(Store.format_time(3725), Store.format_time(0.04))
io.write(s:serialize())
local copy = Store.parse(s:serialize())
print("round trip:", copy:count(), copy.items[3].title)
