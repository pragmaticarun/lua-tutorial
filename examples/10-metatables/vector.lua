-- vector.lua: arithmetic, comparison and tostring metamethods
local V = {}
V.__index = V
local function vec(x, y) return setmetatable({ x = x, y = y }, V) end

V.__add = function(a, b) return vec(a.x + b.x, a.y + b.y) end
V.__sub = function(a, b) return vec(a.x - b.x, a.y - b.y) end
V.__mul = function(a, b)                   -- number * vec or vec * number
  if type(a) == "number" then return vec(a * b.x, a * b.y) end
  return vec(a.x * b, a.y * b)
end
V.__unm = function(a) return vec(-a.x, -a.y) end
V.__eq = function(a, b) return a.x == b.x and a.y == b.y end
V.__tostring = function(a) return "(" .. a.x .. ", " .. a.y .. ")" end
V.__concat = function(a, b) return tostring(a) .. tostring(b) end
function V.len(a) return math.sqrt(a.x * a.x + a.y * a.y) end

local a, b = vec(3, 4), vec(1, 2)
print(tostring(a + b), tostring(a - b), tostring(2 * b), tostring(b * 3), tostring(-a))
print(a == vec(3, 4), a == b, rawequal(a, vec(3, 4)))
print("a = " .. a, a:len())
