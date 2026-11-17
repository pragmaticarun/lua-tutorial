-- Exercise 4 solution: interleave any number of generators round-robin
local function count(prefix, n)
  return coroutine.wrap(function() for i = 1, n do coroutine.yield(prefix .. i) end end)
end
local function interleave(...)
  local gens = { ... }
  return coroutine.wrap(function()
    while #gens > 0 do
      local i = 1
      while i <= #gens do
        local v = gens[i]()
        if v == nil then table.remove(gens, i)       -- exhausted
        else coroutine.yield(v); i = i + 1 end
      end
    end
  end)
end
local out = {}
for v in interleave(count("v", 3), count("a", 5), count("s", 1)) do out[#out + 1] = v end
print(table.concat(out, " "))
