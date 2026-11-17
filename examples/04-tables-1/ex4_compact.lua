-- Exercise 4 solution: remove holes so # becomes reliable again
local function compact(t, n)          -- n = how many slots to inspect
  local out = {}
  for i = 1, n do
    if t[i] ~= nil then out[#out + 1] = t[i] end
  end
  return out
end
local sparse = { "a", nil, "b", nil, nil, "c" }
local dense = compact(sparse, 6)
print(#dense, table.concat(dense, ","))
