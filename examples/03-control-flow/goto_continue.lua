-- goto_continue.lua: Lua has 'break' but no 'continue'; goto fills the gap
for i = 1, 6 do
  if i % 2 == 0 then goto continue end
  io.write(i, " ")
  ::continue::
end
print()

-- breaking out of nested loops
local grid = { { 1, 2, 3 }, { 4, 42, 6 }, { 7, 8, 9 } }
for r = 1, #grid do
  for c = 1, #grid[r] do
    if grid[r][c] == 42 then
      print("found 42 at", r, c)
      goto found
    end
  end
end
print("not found")
::found::
print("done")
