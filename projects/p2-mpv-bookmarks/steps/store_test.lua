-- A dependency-free test of store.lua (the same idea as a busted spec): each
-- check prints nothing on success; failures are listed, then a summary.
package.path = "../bookmarks/?.lua;" .. package.path
local Store = require("store")

local checks, failed = 0, 0
local function check(name, got, want)
  checks = checks + 1
  if got ~= want then
    failed = failed + 1
    print(("FAIL %s: got %s, want %s"):format(name, tostring(got), tostring(want)))
  end
end

local s = Store.new({ { time = 30 }, { time = 10, title = "A" }, { time = 20, title = "B" } })
check("sorted on load", s.items[1].title, "A")
check("default title: numbered in the order added", s.items[3].title, "Bookmark 1")
check("merge keeps count", (function() s:add(10.4, "A2") return s:count() end)(), 3)
check("merge renames", s.items[1].title, "A2")
check("insert in the middle", (function() s:add(15) return s.items[2].time end)(), 15)
check("next skips current", s:next_after(15).time, 20)
check("prev", s:prev_before(20).time, 15)
check("no next at the end", s:next_after(30), nil)
check("remove nearest", s:remove_near(16).time, 15)
check("format minutes", Store.format_time(75.5), "01:15.5")
check("format hours", Store.format_time(3725), "1:02:05.0")
check("tab in title survives", Store.parse(Store.new({ { time = 1, title = "a\tb" } }):serialize()).items[1].title, "a b")
check("bad lines ignored", Store.parse("x\n1.5\tok\n\n").count(Store.parse("x\n1.5\tok\n\n")), 1)
check("chapters", #s:to_chapters(), 3)
print(("%d checks, %d failed"):format(checks, failed))
