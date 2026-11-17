-- half_done: changes half the frame, then fails. The host restores the frame
-- from its backup, so the next filter sees the frame as it was.
function process(frame)
  for y = 0, frame.height / 2 - 1 do
    for x = 0, frame.width - 1 do frame:set(x, y, 0) end
  end
  error("codec exploded halfway through")
end
