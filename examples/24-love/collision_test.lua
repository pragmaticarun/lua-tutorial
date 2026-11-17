-- The collision module under plain Lua: no LÖVE needed.
package.path = "game/?.lua;" .. package.path
local col = require("collision")

local a = { x = 0, y = 0, w = 10, h = 10 }
print("overlap      ", col.aabb(a, { x = 5, y = 5, w = 10, h = 10 }))
print("touching edge", col.aabb(a, { x = 10, y = 0, w = 5, h = 5 }))   -- strict <
print("apart        ", col.aabb(a, { x = 20, y = 0, w = 5, h = 5 }))

print("circles      ", col.circles({ x = 0, y = 0, r = 5 }, { x = 8, y = 0, r = 4 }),
                       col.circles({ x = 0, y = 0, r = 5 }, { x = 9, y = 0, r = 4 }))

-- circle vs box: near a corner the bounding boxes overlap but the shapes do not
local box = { x = 10, y = 10, w = 20, h = 20 }
print("corner miss  ", col.circle_rect({ x = 6, y = 6, r = 5 }, box))
print("edge hit     ", col.circle_rect({ x = 6, y = 20, r = 5 }, box))

-- resolution: smallest push out of the wall
local wall = { x = 0, y = 50, w = 100, h = 10 }
local function show(b)
  local mx, my = col.resolve(b, wall)
  print(("push %-8s -> %s, %s"):format(("(%d,%d)"):format(b.x, b.y), tostring(mx), tostring(my)))
end
show({ x = 10, y = 45, w = 10, h = 10 })   -- landed on top: push up 5
show({ x = 10, y = 55, w = 10, h = 10 })   -- from below: push down 5
show({ x = -8, y = 52, w = 10, h = 6 })    -- from the left side: push left 2
show({ x = 10, y = 20, w = 10, h = 10 })   -- not touching: nil
