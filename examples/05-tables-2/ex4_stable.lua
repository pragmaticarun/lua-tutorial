-- Exercise 4 solution: a stable sort on top of table.sort (which is not stable)
local function stable_sort(list, less)
  local decorated = {}
  for i, v in ipairs(list) do decorated[i] = { v = v, i = i } end
  table.sort(decorated, function(a, b)
    if less(a.v, b.v) then return true end
    if less(b.v, a.v) then return false end
    return a.i < b.i                     -- equal keys keep their original order
  end)
  for i, d in ipairs(decorated) do list[i] = d.v end
  return list
end
local tracks = { { "intro", 2 }, { "verse", 1 }, { "chorus", 2 }, { "bridge", 1 }, { "outro", 2 } }
stable_sort(tracks, function(a, b) return a[2] < b[2] end)
for _, t in ipairs(tracks) do io.write(t[1], "(", t[2], ") ") end
print()
