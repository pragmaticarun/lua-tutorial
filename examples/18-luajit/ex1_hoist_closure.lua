-- targets: jit
-- Exercise 1 solution: find and remove a trace abort
local function count_aborts(fn)
  local aborts, stops = 0, 0
  local function handler(what)
    if what == "abort" then aborts = aborts + 1 elseif what == "stop" then stops = stops + 1 end
  end
  jit.attach(handler, "trace")
  fn()
  jit.attach(handler)                    -- detach: the same function, no event
  return stops, aborts
end

local frames = {}
for i = 1, 2000 do frames[i] = { pts = (i * 7919) % 2000, size = i } end

local function slow()
  local total = 0
  for i = 1, #frames do
    local f = frames[i]
    -- a closure created per iteration: FNEW is not compiled
    local scaled = (function(x) return x * 2 end)(f.size)
    total = total + scaled
  end
  return total
end

local function double(x) return x * 2 end
local function fast()
  local total = 0
  for i = 1, #frames do total = total + double(frames[i].size) end
  return total
end

for _, case in ipairs({ { "slow", slow }, { "fast", fast } }) do
  local result
  local stops, aborts = count_aborts(function() result = case[2]() end)
  print(("%s: result=%d traces=%d aborts=%d"):format(case[1], result, stops, aborts))
end
