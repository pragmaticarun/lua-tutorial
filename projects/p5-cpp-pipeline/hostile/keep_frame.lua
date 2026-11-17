-- keep_frame: keeps the frame userdata in a global and uses it on the next
-- call. The host expires each frame handle when process() returns.
local previous
function process(frame)
  if previous then
    print("previous frame is", tostring(previous))
    print("reading it:", previous:get(0, 0))
  end
  previous = frame
end
