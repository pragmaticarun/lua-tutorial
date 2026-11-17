-- locals.lua: globals by default, locals by habit
x = 10                 -- global: actually _G.x
local y = 20           -- local: lives in a VM register, visible to this chunk

do
  local y = 99         -- shadows the outer y inside this block only
  print("inner y", y)
end
print("outer y", y, "global x", _G.x)

-- the bug that the 'local' habit prevents: a typo silently reads a global
local function total(items)
  local sum = 0
  for i = 1, #items do
    sum = sum + items[i]
  end
  return summ          -- typo! reads global 'summ', which is nil
end
print("total:", total({1, 2, 3}))
