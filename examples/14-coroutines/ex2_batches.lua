-- Exercise 2 solution: yield an array in batches of n
local function batches(list, n)
  return coroutine.wrap(function()
    for i = 1, #list, n do
      local batch = {}
      for j = i, math.min(i + n - 1, #list) do batch[#batch + 1] = list[j] end
      coroutine.yield(batch, i)
    end
  end)
end
local frames = {}
for i = 1, 7 do frames[i] = "f" .. i end
for batch, first in batches(frames, 3) do print(first, table.concat(batch, ",")) end
