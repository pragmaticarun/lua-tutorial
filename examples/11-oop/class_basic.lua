-- class_basic.lua: a class is a table of methods used as __index
local Track = {}
Track.__index = Track                     -- instances look up missing keys in Track

function Track.new(title, seconds)        -- constructor
  local self = setmetatable({}, Track)
  self.title, self.seconds = title, seconds
  return self
end

function Track:duration()                 -- ':' adds an implicit 'self' parameter
  return string.format("%d:%02d", math.floor(self.seconds / 60), self.seconds % 60)
end

function Track:rename(title) self.title = title; return self end  -- chainable

local t = Track.new("Intro", 95)
print(t.title, t:duration())
print(t:rename("Overture"):duration(), t.title)
print(rawget(t, "duration"), getmetatable(t) == Track)  -- methods live in Track only
