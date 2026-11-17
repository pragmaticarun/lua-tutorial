-- Exercise 3 (solution): mirror left-right in place by swapping pixel pairs.
function process(frame)
  local w = frame.width
  for y = 0, frame.height - 1 do
    for x = 0, math.floor(w / 2) - 1 do
      local a, b = frame:get(x, y), frame:get(w - 1 - x, y)
      frame:set(x, y, b)
      frame:set(w - 1 - x, y, a)
    end
  end
end
