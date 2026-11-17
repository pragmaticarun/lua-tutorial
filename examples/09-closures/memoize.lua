-- memoize.lua: caching results in a closure
local function memoize(f)
  local cache = {}
  return function(n)
    local v = cache[n]
    if v == nil then
      v = f(n)
      cache[n] = v
    end
    return v
  end
end

local calls = 0
local fib
fib = memoize(function(n)
  calls = calls + 1
  if n < 2 then return n end
  return fib(n - 1) + fib(n - 2)       -- recursive calls go through the cache
end)
print(fib(80), "computed with", calls, "calls")
print(fib(80), "second time:", calls, "calls")
