-- Exercise 3 (solution): check level layouts before the game uses them.
package.path = "../game/?.lua;" .. package.path

local function validate(level, columns)
  local problems, bricks = {}, 0
  if #level == 0 then problems[#problems + 1] = "no rows" end
  for row, line in ipairs(level) do
    if #line ~= columns then
      problems[#problems + 1] = ("row %d has %d columns, expected %d"):format(row, #line, columns)
    end
    local bad = line:match("[^#2%.]")
    if bad then problems[#problems + 1] = ("row %d: unknown brick '%s'"):format(row, bad) end
    for _ in line:gmatch("[#2]") do bricks = bricks + 1 end
  end
  if bricks == 0 then problems[#problems + 1] = "no bricks to break" end
  return #problems == 0, problems, bricks
end

for i, level in ipairs(require("src.levels")) do
  local ok, _, n = validate(level, 10)
  print(("level %d: %s, %d bricks"):format(i, ok and "ok" or "INVALID", n))
end
local ok, problems = validate({ "####", "#x##.", "...." }, 4)
print("broken level ok?", ok)
for _, p in ipairs(problems) do print("  " .. p) end
