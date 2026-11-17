-- Exercise 1 (solution): unsharp masking. sharpened = v + amount * (v - blurred)
local amount = params.amount or 1.0

function process(frame)
  local w, h = frame.width, frame.height
  local src = {}
  for y = 0, h - 1 do
    for x = 0, w - 1 do src[y * w + x] = frame:get(x, y) end
  end
  for y = 1, h - 2 do                       -- leave the 1-pixel border alone
    for x = 1, w - 2 do
      local sum = 0
      for dy = -1, 1 do
        for dx = -1, 1 do sum = sum + src[(y + dy) * w + x + dx] end
      end
      local v = src[y * w + x]
      frame:set(x, y, v + amount * (v - sum / 9))
    end
  end
end
