-- Exercise 2 (solution): motion detection. A script's state lives as long as
-- the script, so keep the previous frame's pixels in a Lua table (never the
-- frame userdata itself, which expires) and compare.
local previous
local threshold = params.threshold or 40

function process(frame)
  local w, h = frame.width, frame.height
  local now, changed = {}, 0
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local v = frame:get(x, y)
      now[y * w + x] = v
      if previous and math.abs(v - previous[y * w + x]) > threshold then changed = changed + 1 end
    end
  end
  if previous then
    print(("%d pixels changed (%.1f%%)"):format(changed, changed * 100 / (w * h)))
  else
    print("first frame: nothing to compare")
  end
  previous = now
end
