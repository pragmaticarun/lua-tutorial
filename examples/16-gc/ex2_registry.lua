-- Exercise 2 solution: count live instances of a class with a weak-key set
local Session = {}
Session.__index = Session
local live = setmetatable({}, { __mode = "k" })

function Session.new(id)
  local s = setmetatable({ id = id }, Session)
  live[s] = true
  return s
end
function Session.live_count()
  collectgarbage()
  local n = 0
  for _ in pairs(live) do n = n + 1 end
  return n
end

local s1, s2, s3 = Session.new(1), Session.new(2), Session.new(3)
print(Session.live_count())
s2 = nil
print(Session.live_count())
s1, s3 = nil, nil
print(Session.live_count())
