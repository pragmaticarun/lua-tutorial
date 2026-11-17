-- Exercise 2 solution: transpose a (possibly non-square) matrix
local function transpose(m)
  local t = {}
  for j = 1, #m[1] do
    t[j] = {}
    for i = 1, #m do t[j][i] = m[i][j] end
  end
  return t
end
local m = { { 1, 2, 3 }, { 4, 5, 6 } }
for _, row in ipairs(transpose(m)) do print(table.concat(row, " ")) end
