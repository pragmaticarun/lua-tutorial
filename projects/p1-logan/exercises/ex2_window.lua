-- Exercise 2 (solution): a --since/--until filter. Minute keys look like
-- "2026-11-17 10:02", so plain string comparison orders them correctly.
package.path = "../src/?.lua;../src/?/init.lua;" .. package.path
local parse = require("logan.parse")
local report = require("logan.report")

local function window(since, till)
  return function(rec)
    return (not since or rec.minute >= since) and (not till or rec.minute <= till)
  end
end

local function run(since, till)
  local keep, st, n = window(since, till), report.new(), 0
  for line in io.lines("../data/access.log") do
    n = n + 1
    local rec = parse.line(line)
    if not rec or keep(rec) then report.add(st, rec, n) end
  end
  print(("since=%-17s until=%-17s parsed=%2d errors=%d"):format(
    tostring(since), tostring(till), st.parsed, st.errors))
end

run(nil, nil)
run("2026-11-17 10:02", nil)
run(nil, "2026-11-17 10:01")
run("2026-11-17 10:02", "2026-11-17 10:02")
