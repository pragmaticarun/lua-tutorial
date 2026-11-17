-- multiret.lua: multiple results and the adjustment rules
local function minmax(t)
  local lo, hi = t[1], t[1]
  for i = 2, #t do
    if t[i] < lo then lo = t[i] end
    if t[i] > hi then hi = t[i] end
  end
  return lo, hi
end
local lo, hi = minmax({ 4, 9, 1, 7 })
print(lo, hi)

local a, b, c = minmax({ 5, 2 })     -- missing results become nil
print(a, b, c)

-- only the LAST expression in a list expands to all its results
print(minmax({ 3, 8 }), "end")       -- first position: truncated to 1 value
print("start", minmax({ 3, 8 }))     -- last position: expanded
local t = { minmax({ 3, 8 }), minmax({ 1, 2 }) }
print(#t)                            -- 3: first call truncated, last expanded
print((minmax({ 3, 8 })))            -- extra parentheses truncate to one value

local x, y = 1, 2
x, y = y, x                          -- multiple assignment: swap
print(x, y)
