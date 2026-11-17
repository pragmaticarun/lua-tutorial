-- basics.lua: create, resume, yield, status - values flow both ways
local co = coroutine.create(function(a, b)
  print("started with", a, b)
  local c = coroutine.yield(a + b)          -- suspend, handing a+b to resume
  print("resumed with", c)
  local d, e = coroutine.yield(c * 2)
  print("resumed with", d, e)
  return "done"
end)
print(coroutine.status(co))                  -- suspended (not started yet)
print(coroutine.resume(co, 1, 2))            -- runs until the first yield
print(coroutine.status(co))
print(coroutine.resume(co, 10))
print(coroutine.resume(co, "x", "y"))        -- runs to the end
print(coroutine.status(co))
print(coroutine.resume(co))                  -- resuming a dead coroutine fails
