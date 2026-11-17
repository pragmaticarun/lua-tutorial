-- Exercise 1 solution: reverse a sequence in place
local function reverse(t)
  local i, j = 1, #t
  while i < j do
    t[i], t[j] = t[j], t[i]     -- multiple assignment swaps without a temp
    i, j = i + 1, j - 1
  end
  return t
end
print(table.concat(reverse({ 1, 2, 3, 4, 5 }), " "))
print(table.concat(reverse({ "a", "b" }), " "))
print(#reverse({}))
