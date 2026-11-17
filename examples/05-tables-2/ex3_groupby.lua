-- Exercise 3 solution: group records by a field
local files = {
  { name = "a.mp4", codec = "h264" }, { name = "b.mkv", codec = "av1" },
  { name = "c.mp4", codec = "h264" }, { name = "d.webm", codec = "vp9" },
  { name = "e.mkv", codec = "av1" },
}
local function group_by(list, field)
  local groups = {}
  for _, item in ipairs(list) do
    local key = item[field]
    local g = groups[key]
    if not g then g = {}; groups[key] = g end
    g[#g + 1] = item
  end
  return groups
end
local groups = group_by(files, "codec")
local keys = {}
for k in pairs(groups) do keys[#keys + 1] = k end
table.sort(keys)
for _, k in ipairs(keys) do
  local names = {}
  for i, f in ipairs(groups[k]) do names[i] = f.name end
  print(k, table.concat(names, ","))
end
