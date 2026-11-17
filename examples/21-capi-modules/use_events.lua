-- use_events.lua: registry references, upvalues and light userdata from C
local events = require("events")

local log = {}
local a = events.on(function(name, v) log[#log + 1] = "A:" .. name .. "=" .. v end)
local b = events.on(function(name, v) log[#log + 1] = "B:" .. name .. "=" .. v end)
print("calls:", events.emit("fps", 30))
print("removed:", events.off(a), events.off(a))
print("calls:", events.emit("fps", 60))
print(table.concat(log, " "))
print(pcall(events.emit, "boom", setmetatable({}, { __concat = function() error("bad value") end })))

local c1, c2 = events.counter(), events.counter(100)
print(c1(), c1(), c1(), c2(), c1())        -- each closure has its own upvalue

local t1, t2 = events.tag(), events.tag()
print(type(t1), t1 == t2)                  -- the same address: equal
