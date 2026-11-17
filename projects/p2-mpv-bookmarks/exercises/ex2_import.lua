-- Exercise 2 (solution): import a file's existing chapters (mpv's
-- chapter-list property) as bookmarks, without duplicating ones we have.
package.path = "../bookmarks/?.lua;" .. package.path
local Store = require("store")

local function import(store, chapters)
  local added = 0
  for _, c in ipairs(chapters) do
    local near = false
    for _, b in ipairs(store.items) do
      if math.abs(b.time - c.time) < Store.MERGE then near = true break end
    end
    if not near then
      store:add(c.time, c.title ~= "" and c.title or nil)
      added = added + 1
    end
  end
  return added
end

local s = Store.new({ { time = 61, title = "My note" } })
local chapters = {                         -- what mp.get_property_native("chapter-list") returns
  { time = 0, title = "Opening" }, { time = 60.8, title = "Chapter 2" }, { time = 300, title = "" },
}
print("imported", import(s, chapters))
for _, l in ipairs(s:lines(0)) do print(l) end
