-- class_helper.lua: a 20-line class() helper (the pattern most Lua libraries use)
local function class(parent)
  local c = {}
  c.__index = c
  if parent then
    setmetatable(c, { __index = parent })
    for k, v in pairs(parent) do                   -- inherit metamethods
      if type(k) == "string" and k:sub(1, 2) == "__" and k ~= "__index" then c[k] = v end
    end
  end
  c.super = parent
  c.new = function(...)
    local obj = setmetatable({}, c)
    if obj.init then obj:init(...) end
    return obj
  end
  return c
end

local Shape = class()
function Shape:init(name) self.name = name end
function Shape:area() return 0 end
Shape.__tostring = function(s) return ("%s with area %.2f"):format(s.name, s:area()) end

local Circle = class(Shape)
function Circle:init(r) Circle.super.init(self, "circle"); self.r = r end
function Circle:area() return math.pi * self.r ^ 2 end

local Rect = class(Shape)
function Rect:init(w, h) Shape.init(self, "rect"); self.w, self.h = w, h end
function Rect:area() return self.w * self.h end

for _, s in ipairs({ Circle.new(1), Rect.new(16, 9), Shape.new("blob") }) do
  print(tostring(s))
end
