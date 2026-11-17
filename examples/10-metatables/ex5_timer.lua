-- targets: 5.5, 5.4
-- Exercise 5 solution: a scope timer with <close>, using an injected clock
local fake_clock = 0
local function scope_timer(label, report)
  local start = fake_clock
  return setmetatable({}, {
    __close = function() report(label, fake_clock - start) end,
  })
end
local function report(label, ms) print(string.format("%-8s %d ms", label, ms)) end
do
  local t <close> = scope_timer("decode", report)
  fake_clock = fake_clock + 16
  do
    local inner <close> = scope_timer("scale", report)
    fake_clock = fake_clock + 4
  end
end
