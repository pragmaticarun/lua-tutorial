-- Exercise 5 solution: is_instance that follows any depth of inheritance
local function class(parent)
  local c = setmetatable({}, { __index = parent })
  c.__index, c.parent = c, parent
  c.new = function(t) return setmetatable(t or {}, c) end
  return c
end
local function is_instance(obj, cls)
  local c = getmetatable(obj)
  while c do
    if c == cls then return true end
    c = rawget(c, "parent")
  end
  return false
end
local Media = class()
local Video = class(Media)
local Movie = class(Video)
local m = Movie.new()
print(is_instance(m, Movie), is_instance(m, Video), is_instance(m, Media))
print(is_instance(Video.new(), Movie), is_instance({}, Media))
