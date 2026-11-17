-- Exercise 1 solution: summarise a CSV file written to a temp path
local path = os.tmpname()
local out = assert(io.open(path, "w"))
out:write("file,codec,seconds\n", "a.mp4,h264,12.5\n", "b.mkv,av1,301\n",
          "c.mp4,h264,47.25\n", "d.webm,vp9,8\n")
out:close()

local per_codec, header = {}, true
for line in io.lines(path) do
  if header then header = false
  else
    local file, codec, secs = line:match("^([^,]+),([^,]+),([^,]+)$")
    local c = per_codec[codec] or { files = 0, seconds = 0 }
    c.files, c.seconds = c.files + 1, c.seconds + tonumber(secs)
    per_codec[codec] = c
  end
end
os.remove(path)
local names = {}
for k in pairs(per_codec) do names[#names + 1] = k end
table.sort(names)
for _, k in ipairs(names) do
  print(("%-5s %d file(s) %8.2f s"):format(k, per_codec[k].files, per_codec[k].seconds))
end
