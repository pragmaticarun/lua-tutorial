-- pipeline.lua: producer -> filter -> consumer, each stage a coroutine
local function producer(n)
  return coroutine.wrap(function()
    for i = 1, n do
      coroutine.yield({ pts = i * 40, key = (i % 4 == 1), size = 1000 + i * 37 % 300 })
    end
  end)
end
local function only_keyframes(source)
  return coroutine.wrap(function()
    for frame in source do
      if frame.key then coroutine.yield(frame) end
    end
  end)
end
local function stats(source)                  -- the consumer pulls frames
  local count, bytes = 0, 0
  for frame in source do
    count, bytes = count + 1, bytes + frame.size
    print("keyframe pts=" .. frame.pts)
  end
  return count, bytes
end
print("total:", stats(only_keyframes(producer(10))))
