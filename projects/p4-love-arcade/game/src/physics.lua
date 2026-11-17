-- physics.lua: circle-vs-rectangle collision for the ball.
local P = {}

--- Does a circle (cx, cy, r) overlap rectangle (x, y, w, h)? If so, also
--- return which axis to bounce on: "x" (hit a side) or "y" (top/bottom).
function P.circle_rect(cx, cy, r, x, y, w, h)
  local nx = math.max(x, math.min(cx, x + w))       -- closest point on the rect
  local ny = math.max(y, math.min(cy, y + h))
  local dx, dy = cx - nx, cy - ny
  if dx * dx + dy * dy > r * r then return false end
  -- penetration depth on each axis decides the bounce direction
  local ox = math.min(cx + r - x, x + w - (cx - r))
  local oy = math.min(cy + r - y, y + h - (cy - r))
  return true, ox < oy and "x" or "y"
end

--- A unit vector (x, y) scaled to `len` (sqrt is exact IEEE everywhere, so
--- this is reproducible across interpreters; sin/cos come from libm).
function P.scale(x, y, len)
  local d = math.sqrt(x * x + y * y)
  return x / d * len, y / d * len
end

return P
