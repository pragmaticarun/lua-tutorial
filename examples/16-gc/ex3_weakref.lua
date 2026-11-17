-- Exercise 3 solution: a weak reference helper for leak tests
local function weakref(obj)
  local box = setmetatable({ obj }, { __mode = "v" })
  return function() return box[1] end
end

local function assert_freed(ref, what)
  collectgarbage(); collectgarbage()
  print(what, ref() == nil and "freed" or "LEAKED")
end

local listeners = {}
local frame = {}
local ref = weakref(frame)
listeners[#listeners + 1] = frame        -- forgotten in a listener list
frame = nil
assert_freed(ref, "frame:")
listeners = nil                          -- fix the leak
assert_freed(ref, "frame:")
