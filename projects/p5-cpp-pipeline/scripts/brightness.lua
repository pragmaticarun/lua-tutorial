-- brightness: parameters come from the command line (brightness.lua:amount=40)
-- in the read-only-by-convention `params` table; values that look like
-- numbers arrive as numbers.
local amount = params.amount or 20
local contrast = params.contrast or 1.0
print(("amount=%d contrast=%.2f"):format(amount, contrast))

function process(frame)
  for y = 0, frame.height - 1 do
    for x = 0, frame.width - 1 do
      local v = (frame:get(x, y) - 128) * contrast + 128 + amount
      frame:set(x, y, v)                   -- the host clamps to 0..255 and rounds
    end
  end
end
