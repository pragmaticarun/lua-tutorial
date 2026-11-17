-- Exercise 3 (solution): name a new bookmark after the chapter it falls in,
-- plus the offset into that chapter: "Chapter 2 +00:12.5".
package.path = "../bookmarks/?.lua;" .. package.path
local Store = require("store")

local function title_for(chapters, t)
  local current
  for _, c in ipairs(chapters) do
    if c.time <= t then current = c else break end   -- chapters are sorted
  end
  if not current then return nil end                   -- before the first chapter
  return ("%s +%s"):format(current.title, Store.format_time(t - current.time))
end

local chapters = { { time = 5, title = "Intro" }, { time = 60, title = "Chapter 2" } }
for _, t in ipairs({ 2, 5, 30.5, 72.5 }) do
  print(t, title_for(chapters, t))
end
