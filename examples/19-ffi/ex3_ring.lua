-- targets: jit
-- Exercise 3 solution: a fixed-size ring buffer of int16 audio samples
local ffi = require("ffi")
local Ring = {}
Ring.__index = Ring
function Ring.new(capacity)
  return setmetatable({ buf = ffi.new("int16_t[?]", capacity), cap = capacity,
                        head = 0, count = 0 }, Ring)
end
function Ring:push(sample)
  self.buf[(self.head + self.count) % self.cap] = sample   -- int16_t: wraps like C
  if self.count < self.cap then self.count = self.count + 1
  else self.head = (self.head + 1) % self.cap end            -- overwrite the oldest
end
function Ring:items()
  local out = {}
  for i = 0, self.count - 1 do out[#out + 1] = self.buf[(self.head + i) % self.cap] end
  return out
end
local r = Ring.new(4)
for _, s in ipairs({ 100, -200, 300, 32767, 32768, 5 }) do r:push(s) end
print(table.concat(r:items(), " "))
