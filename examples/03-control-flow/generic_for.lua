-- generic_for.lua: for k, v in iterator do
local codecs = { "h264", "hevc", "av1" }
for i, name in ipairs(codecs) do       -- ipairs: 1..n in order
  print(i, name)
end

local bitrate = { h264 = 8000, av1 = 4500, hevc = 5000 }
-- pairs visits every key, in an UNSPECIFIED order. Sort when order matters:
local keys = {}
for k in pairs(bitrate) do keys[#keys + 1] = k end
table.sort(keys)
for _, k in ipairs(keys) do print(k, bitrate[k]) end

-- ipairs stops at the first nil
local holes = { "a", "b", nil, "d" }
local count = 0
for _ in ipairs(holes) do count = count + 1 end
print("ipairs saw", count)
