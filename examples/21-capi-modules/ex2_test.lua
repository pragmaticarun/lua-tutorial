-- Exercise 2 test: metadata stays alive as long as the userdata does
local node = require("ex2_node")
local probe = setmetatable({}, { __mode = "v" })
local n
do
  local meta = { codec = "h264", tracks = 2 }
  probe[1] = meta
  n = node.new(7, meta)
end
collectgarbage(); collectgarbage()
print(n.id, n.codec, n.tracks, probe[1] ~= nil)   -- still reachable via the user value
n = nil
collectgarbage(); collectgarbage()
print(probe[1] == nil)                            -- freed together with the userdata
