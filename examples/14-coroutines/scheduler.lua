-- scheduler.lua: a tiny cooperative scheduler with virtual time
local tasks, now = {}, 0
local function spawn(name, fn) tasks[#tasks + 1] = { name = name, co = coroutine.create(fn), wake = 0 } end
local function sleep(ticks) coroutine.yield(ticks) end

local function run()
  while #tasks > 0 do
    table.sort(tasks, function(a, b)                 -- earliest wake time first
      if a.wake ~= b.wake then return a.wake < b.wake end
      return a.name < b.name
    end)
    local t = table.remove(tasks, 1)
    now = math.max(now, t.wake)
    local ok, ticks = coroutine.resume(t.co)
    if not ok then print(("[%3d] %s crashed: %s"):format(now, t.name, ticks))
    elseif coroutine.status(t.co) ~= "dead" then
      t.wake = now + ticks
      tasks[#tasks + 1] = t
    end
  end
end

spawn("osd", function()
  for i = 1, 3 do print(("[%3d] osd: refresh %d"):format(now, i)); sleep(50) end
end)
spawn("decoder", function()
  for frame = 1, 4 do print(("[%3d] decoder: frame %d"):format(now, frame)); sleep(40) end
end)
spawn("watchdog", function() sleep(100); error("no input for 100 ticks", 0) end)
run()
