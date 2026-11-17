-- Exercise 1 solution: memoize a function of one table argument, without leaks
local function memoize(f)
  local cache = setmetatable({}, { __mode = "k" })   -- keyed by the argument
  return function(arg)
    local r = cache[arg]
    if r == nil then r = f(arg); cache[arg] = r end
    return r
  end, cache
end

local calls = 0
local area, cache = memoize(function(rect) calls = calls + 1; return rect.w * rect.h end)
local r1 = { w = 1920, h = 1080 }
print(area(r1), area(r1), calls)
local r2 = { w = 4, h = 3 }
print(area(r2), calls)

r1, r2 = nil, nil
collectgarbage()
print("cached entries:", next(cache) == nil and 0 or "some")
