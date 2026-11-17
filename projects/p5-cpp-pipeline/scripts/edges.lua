-- edges: Sobel edge detection, |gx| + |gy| (cheaper than the true magnitude).
local K = { -1, 0, 1, -2, 0, 2, -1, 0, 1 }      -- horizontal gradient kernel

function process(frame)
  local w, h = frame.width, frame.height
  local src = {}
  for y = 0, h - 1 do
    for x = 0, w - 1 do src[y * w + x] = frame:get(x, y) end
  end
  local function at(x, y)                      -- clamp at the borders
    x = math.max(0, math.min(w - 1, x))
    y = math.max(0, math.min(h - 1, y))
    return src[y * w + x]
  end
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local gx, gy, i = 0, 0, 1
      for dy = -1, 1 do
        for dx = -1, 1 do
          local v = at(x + dx, y + dy)
          gx = gx + K[i] * v
          gy = gy + K[(dx + 1) * 3 + dy + 2] * v   -- the same kernel, transposed
          i = i + 1
        end
      end
      frame:set(x, y, (math.abs(gx) + math.abs(gy)) / 4)
    end
  end
end
