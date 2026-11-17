-- module
-- Pure collision math: no love.* calls, so it runs (and is tested) under
-- plain Lua 5.5, 5.4 and LuaJIT as well as inside LÖVE.
local M = {}

-- Axis-aligned bounding boxes: {x, y, w, h} with (x, y) the top-left corner.
function M.aabb(a, b)
  return a.x < b.x + b.w and b.x < a.x + a.w
     and a.y < b.y + b.h and b.y < a.y + a.h
end

-- Circles: {x, y, r} with (x, y) the centre. Compare squared distances.
function M.circles(a, b)
  local dx, dy, r = a.x - b.x, a.y - b.y, a.r + b.r
  return dx * dx + dy * dy < r * r
end

local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end
M.clamp = clamp

-- Circle vs box: the closest point of the box to the centre decides.
function M.circle_rect(c, r)
  local px = clamp(c.x, r.x, r.x + r.w)
  local py = clamp(c.y, r.y, r.y + r.h)
  local dx, dy = c.x - px, c.y - py
  return dx * dx + dy * dy < c.r * c.r
end

-- Minimum translation vector to push box a out of box b (nil if apart).
-- Resolving along the axis of least overlap is the classic platformer trick.
function M.resolve(a, b)
  if not M.aabb(a, b) then return nil end
  local left  = (a.x + a.w) - b.x   -- push a left by this much
  local right = (b.x + b.w) - a.x   -- push a right
  local up    = (a.y + a.h) - b.y
  local down  = (b.y + b.h) - a.y
  local mx = left < right and -left or right
  local my = up < down and -up or down
  if math.abs(mx) < math.abs(my) then return mx, 0 else return 0, my end
end

return M
