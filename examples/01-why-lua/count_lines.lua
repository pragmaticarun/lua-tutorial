-- stdin: count_lines.input
-- count_lines.lua: read stdin line by line, count log levels
local counts = {}
local total = 0
for line in io.lines() do
  local level = line:match("^(%u+)")   -- leading upper-case word
  if level then
    counts[level] = (counts[level] or 0) + 1
    total = total + 1
  end
end
print("lines:", total)
for _, level in ipairs({"INFO", "WARN", "ERROR"}) do
  print(level, counts[level] or 0)
end
