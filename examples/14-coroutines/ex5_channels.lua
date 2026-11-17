-- Exercise 5 solution: tasks that block on a channel until a message arrives
local ready, waiting = {}, {}
local function spawn(fn) ready[#ready + 1] = coroutine.create(fn) end
local Channel = {}
Channel.__index = Channel
function Channel.new(name) return setmetatable({ name = name, queue = {} }, Channel) end
function Channel:send(v)
  table.insert(self.queue, v)
  local w = waiting[self]
  if w and #w > 0 then ready[#ready + 1] = table.remove(w, 1) end  -- wake a receiver
end
function Channel:receive()
  while #self.queue == 0 do
    waiting[self] = waiting[self] or {}
    table.insert(waiting[self], (coroutine.running()))
    coroutine.yield()
  end
  return table.remove(self.queue, 1)
end
local function yield_now()                       -- give other tasks a turn
  ready[#ready + 1] = (coroutine.running())
  coroutine.yield()
end
local function run()
  while #ready > 0 do
    local co = table.remove(ready, 1)
    assert(coroutine.resume(co))
  end
end

local frames = Channel.new("frames")
spawn(function()
  for i = 1, 3 do print("encoder got", frames:receive()) end
  print("encoder done")
end)
spawn(function()
  for i = 1, 3 do print("decoder sends frame", i); frames:send("frame" .. i); yield_now() end
end)
run()
