-- matrix.lua: a matrix as an array of row arrays
local function matrix(rows, cols, f)
  local m = {}
  for i = 1, rows do
    local row = {}
    for j = 1, cols do row[j] = f(i, j) end
    m[i] = row
  end
  return m
end
local function mul(a, b)
  return matrix(#a, #b[1], function(i, j)
    local s = 0
    for k = 1, #b do s = s + a[i][k] * b[k][j] end
    return s
  end)
end
local function show(m)
  for i = 1, #m do
    local cells = {}
    for j = 1, #m[i] do cells[j] = string.format("%4d", m[i][j]) end
    print(table.concat(cells))
  end
end
local a = { { 1, 2 }, { 3, 4 } }
local identity = matrix(2, 2, function(i, j) return i == j and 1 or 0 end)
show(mul(a, a))
show(mul(a, identity))
