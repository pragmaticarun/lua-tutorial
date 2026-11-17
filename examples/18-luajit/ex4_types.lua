-- targets: jit
-- Exercise 4 solution: type-unstable data makes extra (side) traces
local function count_traces(fn)
  local n = 0
  local function handler(what) if what == "stop" then n = n + 1 end end
  jit.attach(handler, "trace")
  fn()
  jit.attach(handler)                    -- detach
  return n
end

local function sum(t)
  local s = 0
  for i = 1, #t do
    local v = t[i]
    if type(v) == "number" then s = s + v else s = s + #v end
  end
  return s
end

local numbers, mixed = {}, {}
for i = 1, 3000 do
  numbers[i] = i
  mixed[i] = (i % 3 == 0) and tostring(i) or i      -- every third value a string
end
print("numbers only:", count_traces(function() sum(numbers) end), "trace(s)")
jit.flush()                                         -- forget compiled traces
print("mixed types: ", count_traces(function() sum(mixed) end), "trace(s)")
