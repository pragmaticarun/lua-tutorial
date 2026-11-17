-- Exercise 1 (solution): priorities. "!!" anywhere in the text is high, "!"
-- is medium; sort open tasks by priority before due date.
package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path
local tasks = require("notes.tasks")

local function priority(t)
  if t.text:find("!!", 1, true) then return 2 end
  if t.text:find("!", 1, true) then return 1 end
  return 0
end

local function sort(list)
  table.sort(list, function(a, b)
    if a.done ~= b.done then return not a.done end
    local pa, pb = priority(a), priority(b)
    if pa ~= pb then return pa > pb end
    if a.due ~= b.due then
      if not a.due then return false end
      if not b.due then return true end
      return a.due < b.due
    end
    return a.lnum < b.lnum
  end)
  return list
end

local list = tasks.collect({
  "- [ ] later @2026-11-18", "- [ ] urgent !! @2026-12-01", "- [x] old !!",
  "- [ ] soonish ! ", "- [ ] whenever",
})
for _, t in ipairs(sort(list)) do print(priority(t), tasks.format(t)) end
