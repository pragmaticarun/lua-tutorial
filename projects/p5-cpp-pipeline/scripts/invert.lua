-- invert: the smallest possible filter. The host calls process(frame) once
-- per frame; frame:get/set read and write 0..255 gray values.
function process(frame)
  for y = 0, frame.height - 1 do
    for x = 0, frame.width - 1 do
      frame:set(x, y, 255 - frame:get(x, y))
    end
  end
end
