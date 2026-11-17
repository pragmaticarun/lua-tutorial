-- varargs.lua: variadic functions with ...
local pack = table.pack or function(...) return { n = select("#", ...), ... } end
local unpack = table.unpack or unpack

local function sum(...)
  local total = 0
  for i = 1, select("#", ...) do
    total = total + (select(i, ...))  -- select(i, ...) returns args i..n; keep one
  end
  return total
end
print(sum(), sum(1, 2, 3), sum(10, 20))

local function count(...) return select("#", ...) end
print(count(nil, nil), #{ nil, nil })  -- select counts trailing nils

local args = pack(1, nil, 3)
print(args.n, unpack(args, 1, args.n))

-- forwarding: wrap any function, passing all arguments and results through
local function logged(name, f)
  return function(...)
    print("call " .. name, ...)
    return f(...)
  end
end
local add = logged("add", function(a, b) return a + b end)
print(add(2, 3))
print(select(-1, "a", "b", "c"))      -- negative index: from the end
