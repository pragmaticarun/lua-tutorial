-- Exercise 2 solution: a small shape hierarchy with overridden methods
local Shape = {}
Shape.__index = Shape
function Shape.new(name) return setmetatable({ name = name }, Shape) end
function Shape:area() error("area() not implemented for " .. self.name) end
function Shape:describe() return ("%-8s area %8.2f"):format(self.name, self:area()) end

local function subclass(base)
  local c = setmetatable({}, { __index = base })
  c.__index = c
  return c
end

local Square = subclass(Shape)
function Square.new(side)
  local self = setmetatable(Shape.new("square"), Square); self.side = side; return self
end
function Square:area() return self.side ^ 2 end

local Triangle = subclass(Shape)
function Triangle.new(b, h)
  local self = setmetatable(Shape.new("triangle"), Triangle); self.b, self.h = b, h; return self
end
function Triangle:area() return 0.5 * self.b * self.h end

for _, s in ipairs({ Square.new(3), Triangle.new(4, 5) }) do print(s:describe()) end
print(pcall(Shape.describe, Shape.new("blob")))
