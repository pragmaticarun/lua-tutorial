-- host: luacheck
-- Deliberately bad code for luacheck and StyLua to complain about.
local unused = 1
local  function area( w,h )
  result = w*h   -- oops: global assignment
  return result
end
local function greet(name, greeting)
    if name == nil then return 'nobody' end
    local name = name:upper()
  return greeting..', '..name
end
print(area(2,3), greet("ann", "hi"), undefined_thing)
