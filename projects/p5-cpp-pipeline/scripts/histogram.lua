-- histogram: a filter that only looks. It prints an 8-bucket histogram and
-- leaves the frame alone (scripts may also just analyse).
function process(frame)
  local buckets = { 0, 0, 0, 0, 0, 0, 0, 0 }
  for y = 0, frame.height - 1 do
    for x = 0, frame.width - 1 do
      local b = math.floor(frame:get(x, y) / 32) + 1
      buckets[b] = buckets[b] + 1
    end
  end
  for i, n in ipairs(buckets) do
    print(("%3d-%3d %4d %s"):format((i - 1) * 32, i * 32 - 1, n, ("#"):rep(math.ceil(n / 40))))
  end
end
