-- inheritance.lua: a subclass is a class whose metatable points at the base class
local Stream = {}
Stream.__index = Stream
function Stream.new(index, codec)
  return setmetatable({ index = index, codec = codec }, Stream)
end
function Stream:describe() return ("#%d %s"):format(self.index, self.codec) end
function Stream:kind() return "stream" end

local VideoStream = setmetatable({}, { __index = Stream })  -- inherit from Stream
VideoStream.__index = VideoStream
function VideoStream.new(index, codec, w, h)
  local self = Stream.new(index, codec)                     -- reuse base init
  self.w, self.h = w, h
  return setmetatable(self, VideoStream)
end
function VideoStream:kind() return "video" end              -- override
function VideoStream:describe()                             -- extend: call "super"
  return Stream.describe(self) .. (" %dx%d"):format(self.w, self.h)
end

local streams = { Stream.new(1, "aac"), VideoStream.new(0, "h264", 1920, 1080) }
for _, s in ipairs(streams) do print(s:kind(), s:describe()) end

local function is_a(obj, class)                             -- walk the chain
  local mt = getmetatable(obj)
  while mt do
    if mt == class then return true end
    local parent = getmetatable(mt)
    mt = parent and parent.__index
  end
  return false
end
print(is_a(streams[2], Stream), is_a(streams[1], VideoStream))
