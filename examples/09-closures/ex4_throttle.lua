-- Exercise 4 solution: throttle(f, interval, clock) - at most one call per interval
local function throttle(f, interval, clock)
  local last = -math.huge
  return function(...)
    local now = clock()
    if now - last >= interval then
      last = now
      return f(...)
    end
  end
end
local fake_time = 0
local function clock() return fake_time end          -- injectable clock for testing
local update_osd = throttle(function(msg) print(fake_time, msg) end, 100, clock)
for t = 0, 350, 50 do
  fake_time = t
  update_osd("position " .. t)
end
