-- loop_capture.lua: every loop iteration gets a fresh control variable
local fs = {}
for i = 1, 3 do
  fs[i] = function() return i end      -- captures this iteration's i
end
print(fs[1](), fs[2](), fs[3]())

-- a variable declared OUTSIDE the loop is shared by all closures
local shared = {}
local j = 0
while j < 3 do
  j = j + 1
  shared[j] = function() return j end
end
print(shared[1](), shared[2](), shared[3]())
