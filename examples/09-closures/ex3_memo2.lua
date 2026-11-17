-- Exercise 3 solution: memoize a two-argument function with a nested cache
local function memoize2(f)
  local cache = {}
  return function(a, b)
    local row = cache[a]
    if not row then row = {}; cache[a] = row end
    local v = row[b]
    if v == nil then v = f(a, b); row[b] = v end
    return v
  end
end
local calls = 0
local scale = memoize2(function(w, h) calls = calls + 1; return w * h end)
print(scale(1920, 1080), scale(1280, 720), scale(1920, 1080))
print("calls:", calls)
