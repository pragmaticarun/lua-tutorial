-- weak_keys.lua: attach data to objects you do not own, without leaking them
local extra = setmetatable({}, { __mode = "k" })

local function tag(obj, label) extra[obj] = label end
local function count()
  local n = 0
  for _ in pairs(extra) do n = n + 1 end
  return n
end

local decoder, encoder = {}, {}
tag(decoder, "hw-accelerated"); tag(encoder, "software")
print(extra[decoder], count())

encoder = nil                             -- the key is only referenced weakly
collectgarbage()
print("after collect:", count())
