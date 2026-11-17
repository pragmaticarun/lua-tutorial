-- Exercise 2 solution: an aligned report with string.format
local rows = {
  { "intro.mp4", 12.5, 1843200 },
  { "keynote-final.mkv", 3605.25, 734003200 },
  { "b.webm", 0.8, 51200 },
}
print(string.format("%-20s %10s %12s", "file", "seconds", "KiB"))
print(string.rep("-", 44))
for _, r in ipairs(rows) do
  print(string.format("%-20s %10.2f %12d", r[1], r[2], math.floor(r[3] / 1024)))
end
