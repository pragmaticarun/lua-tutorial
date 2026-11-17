-- Exercise 1 (solution): export bookmarks as an FFmpeg FFMETADATA chapter
-- file, so `ffmpeg -i in.mkv -i marks.txt -map_metadata 1 -c copy out.mkv`
-- writes them into the file. Each chapter ends where the next begins.
package.path = "../bookmarks/?.lua;" .. package.path
local Store = require("store")

local function ffmetadata(store, duration)
  local out = { ";FFMETADATA1" }
  for i, b in ipairs(store.items) do
    local finish = store.items[i + 1] and store.items[i + 1].time or duration
    out[#out + 1] = "[CHAPTER]\nTIMEBASE=1/1000"
    out[#out + 1] = ("START=%d\nEND=%d"):format(math.floor(b.time * 1000 + 0.5), math.floor(finish * 1000 + 0.5))
    -- '=', ';', '#', '\' and newlines must be escaped with a backslash
    out[#out + 1] = "title=" .. b.title:gsub("[=;#\\\n]", "\\%0")
  end
  return table.concat(out, "\n") .. "\n"
end

local s = Store.new({ { time = 0, title = "Intro" }, { time = 4.2, title = "Q&A; part 1" },
                      { time = 7.52, title = "Credits" } })
io.write(ffmetadata(s, 10))
