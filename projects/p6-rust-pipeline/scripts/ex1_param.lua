-- Exercise 1 (Rust host only): typed parameters through param(name, default).
local gain = param("gain", 1.0)
local label = param("label", "untitled")
print("gain", gain, "label", label, "missing", param("missing", 7))

function process(frame)
  for y = 0, frame.height - 1 do
    for x = 0, frame.width - 1 do frame:set(x, y, frame:get(x, y) * gain) end
  end
end
