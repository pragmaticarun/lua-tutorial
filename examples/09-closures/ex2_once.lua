-- Exercise 2 solution: once(f) runs f at most once and caches all its results
local unpack = table.unpack or unpack
local function pack(...) return { n = select("#", ...), ... } end

local function once(f)
  local results
  return function(...)
    if not results then results = pack(f(...)) end
    return unpack(results, 1, results.n)
  end
end

local init = once(function(name)
  print("initialising " .. name)
  return "ready", 42
end)
print(init("decoder"))
print(init("ignored"))          -- f is not called again
