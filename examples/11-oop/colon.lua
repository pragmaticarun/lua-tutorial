-- colon.lua: obj:m(x) is sugar for obj.m(obj, x)
local Counter = {}
Counter.__index = Counter
function Counter.new() return setmetatable({ n = 0 }, Counter) end
function Counter:inc(by) self.n = self.n + (by or 1); return self.n end

local c = Counter.new()
print(c:inc(), c.inc(c, 5), Counter.inc(c))   -- three equivalent calls
print(pcall(c.inc, 5))                         -- forgot the colon: self is 5
