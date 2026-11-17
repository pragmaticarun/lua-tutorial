-- Exercise 1: push a circle out of a box along the shortest vector.
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function push_circle(c, r)
  local px, py = clamp(c.x, r.x, r.x + r.w), clamp(c.y, r.y, r.y + r.h)
  local dx, dy = c.x - px, c.y - py
  local d2 = dx * dx + dy * dy
  if d2 >= c.r * c.r then return 0, 0 end              -- not touching
  if d2 == 0 then                                      -- centre inside the box:
    local opts = {                                     -- leave through the nearest side
      { c.x - r.x + c.r, -1, 0 }, { r.x + r.w - c.x + c.r, 1, 0 },
      { c.y - r.y + c.r, 0, -1 }, { r.y + r.h - c.y + c.r, 0, 1 },
    }
    table.sort(opts, function(a, b) return a[1] < b[1] end)
    return opts[1][2] * opts[1][1], opts[1][3] * opts[1][1]
  end
  local d = math.sqrt(d2)
  local depth = c.r - d
  return dx / d * depth, dy / d * depth
end

local box = { x = 0, y = 0, w = 10, h = 10 }
for _, c in ipairs({ { x = 13, y = 5, r = 4 }, { x = 5, y = -2, r = 3 },
                     { x = 12, y = 12, r = 4 }, { x = 8, y = 5, r = 1 }, { x = 20, y = 5, r = 2 } }) do
  local mx, my = push_circle(c, box)
  print(("circle (%g,%g) r=%g -> push (%.3f, %.3f)"):format(c.x, c.y, c.r, mx, my))
end
