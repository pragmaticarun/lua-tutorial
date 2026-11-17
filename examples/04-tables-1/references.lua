-- references.lua: tables are reference values
local a = { 1, 2, 3 }
local b = a                -- copies the reference, not the table
b[1] = 100
print(a[1])                -- 100: a and b are the same table

print({} == {}, a == b)    -- equality is identity

local function shallow_copy(t)
  local c = {}
  for k, v in pairs(t) do c[k] = v end
  return c
end
local c = shallow_copy(a)
c[1] = 1
print(a[1], c[1], a == c)

local nested = { inner = { x = 1 } }
local copy = shallow_copy(nested)
copy.inner.x = 99          -- shallow: the inner table is shared
print(nested.inner.x)
