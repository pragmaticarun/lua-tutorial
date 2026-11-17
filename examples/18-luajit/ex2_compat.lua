-- Exercise 2 solution: one file that runs on Lua 5.1/LuaJIT, 5.4 and 5.5
local compat = {}
compat.unpack = table.unpack or unpack
compat.pack = table.pack or function(...) return { n = select("#", ...), ... } end
if bit then                                      -- LuaJIT's bit library
  compat.band, compat.bor, compat.lshift = bit.band, bit.bor, bit.lshift
else                                             -- 5.3+ operators, hidden from
  compat.band, compat.bor, compat.lshift =       -- older parsers by load()
    load("return function(a, b) return a & b end")(),
    load("return function(a, b) return a | b end")(),
    load("return function(a, n) return a << n end")()
end
compat.idiv = function(a, b) return math.floor(a / b) end
compat.isint = math.type and function(x) return math.type(x) == "integer" end
  or function(x) return type(x) == "number" and x == math.floor(x) end

local packed = compat.pack(1, nil, 3)
print(packed.n, compat.unpack({ 10, 20, 30 }, 2, 3))
print(compat.band(0xF0F, 0x0FF), compat.bor(1, 4), compat.lshift(1, 10))
print(compat.idiv(7, 2), compat.idiv(-7, 2), compat.isint(4), compat.isint(4.5))
