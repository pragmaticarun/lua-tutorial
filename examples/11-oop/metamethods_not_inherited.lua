-- metamethods_not_inherited.lua: __tostring etc. are NOT found through __index
local Base = {}
Base.__index = Base
Base.__tostring = function(self) return "Base(" .. self.name .. ")" end
function Base.new(name) return setmetatable({ name = name }, Base) end

local Derived = setmetatable({}, { __index = Base })
Derived.__index = Derived
function Derived.new(name) return setmetatable(Base.new(name), Derived) end

print(tostring(Base.new("a")))
print((tostring(Derived.new("b")):gsub("0x%x+", "ADDR")))   -- default tostring!

-- fix: copy metamethods into the subclass
for _, k in ipairs({ "__tostring", "__eq", "__lt", "__le", "__concat", "__len" }) do
  if rawget(Derived, k) == nil then Derived[k] = rawget(Base, k) end
end
print(tostring(Derived.new("c")))
