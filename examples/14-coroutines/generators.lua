-- generators.lua: coroutine.wrap turns any recursive walk into an iterator
local function permutations(list)
  local function permute(n)
    if n <= 1 then
      coroutine.yield(list)
    else
      for i = 1, n do
        list[n], list[i] = list[i], list[n]
        permute(n - 1)
        list[n], list[i] = list[i], list[n]
      end
    end
  end
  return coroutine.wrap(function() permute(#list) end)
end
for p in permutations({ "a", "b", "c" }) do io.write(table.concat(p), " ") end
print()

local function walk(tree, depth)              -- depth-first tree traversal
  depth = depth or 0
  coroutine.yield(tree.name, depth)
  for _, child in ipairs(tree.children or {}) do walk(child, depth + 1) end
end
local tree = { name = "pipeline", children = {
  { name = "demux", children = { { name = "video" }, { name = "audio" } } },
  { name = "mux" } } }
for name, depth in coroutine.wrap(function() walk(tree) end) do
  print(string.rep("  ", depth) .. name)
end
