-- queue.lua: an O(1) double-ended queue using two indices
local Deque = {}
function Deque.new() return { first = 1, last = 0 } end
function Deque.push_back(q, v) q.last = q.last + 1; q[q.last] = v end
function Deque.push_front(q, v) q.first = q.first - 1; q[q.first] = v end
function Deque.pop_front(q)
  if q.first > q.last then return nil end
  local v = q[q.first]
  q[q.first] = nil                  -- let the GC reclaim the slot
  q.first = q.first + 1
  return v
end
function Deque.size(q) return q.last - q.first + 1 end

local q = Deque.new()
Deque.push_back(q, "frame1"); Deque.push_back(q, "frame2")
Deque.push_front(q, "keyframe")    -- index 0: keys need not start at 1
print(Deque.size(q))
while Deque.size(q) > 0 do print(Deque.pop_front(q)) end
