-- Exercise 4 solution: compose any number of single-argument functions
local function compose(...)
  local fs = { ... }
  return function(x)
    for i = #fs, 1, -1 do x = fs[i](x) end    -- right to left, like math
    return x
  end
end
local inc = function(x) return x + 1 end
local dbl = function(x) return x * 2 end
print(compose(inc, dbl)(5))     -- inc(dbl(5)) = 11
print(compose(dbl, inc)(5))     -- dbl(inc(5)) = 12
print(compose()(5))             -- identity
local slug = compose(string.lower, function(s) return (s:gsub("%s+", "-")) end)
print(slug("Hello Lua World"))
