-- blur: a 3x3 box blur. Reading and writing the same frame would blur with
-- already-blurred neighbours, so read everything into a Lua table first.
local radius = params.radius or 1

function process(frame)
  local w, h = frame.width, frame.height
  local src = {}
  for y = 0, h - 1 do
    for x = 0, w - 1 do src[y * w + x] = frame:get(x, y) end
  end
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local sum, n = 0, 0
      for dy = -radius, radius do
        for dx = -radius, radius do
          local xx, yy = x + dx, y + dy
          if xx >= 0 and xx < w and yy >= 0 and yy < h then
            sum, n = sum + src[yy * w + xx], n + 1
          end
        end
      end
      frame:set(x, y, sum / n)
    end
  end
end
