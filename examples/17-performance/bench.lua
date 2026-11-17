-- module
-- bench.lua: a tiny benchmark harness used by every example in this lesson.
--
-- bench.compare(title, cases): each case is { label, fn }; fn() does the work
-- and returns a checksum. All variants must return the same checksum.
--   * normal run (what tests/run_all.sh checks): run each case once and print
--     whether the variants agree - deterministic output.
--   * LUA_BENCH=1: time each case with os.clock (CPU time), best of 5 runs,
--     and print tab-separated "BENCH title label ms" lines.
local M = {}
local clock = os.clock

local function best_of(fn, runs)
  local best = math.huge
  for _ = 1, runs do
    collectgarbage(); collectgarbage()           -- start each run from a clean heap
    local t0 = clock()
    fn()
    local dt = clock() - t0
    if dt < best then best = dt end
  end
  return best
end

function M.compare(title, cases)
  local reference = cases[1][2]()
  for i = 2, #cases do
    local got = cases[i][2]()
    if got ~= reference then
      error(("%s: %s returned %s, expected %s"):format(title, cases[i][1],
        tostring(got), tostring(reference)))
    end
  end
  if os.getenv("LUA_BENCH") then
    for _, case in ipairs(cases) do
      print(("BENCH\t%s\t%s\t%.2f"):format(title, case[1], best_of(case[2], 5) * 1000))
    end
  else
    print(("%s: all variants agree (checksum %s)"):format(title, tostring(reference)))
  end
end

return M
