-- Exercise 2 (solution): progress per tag, as a text bar.
package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path
local tasks = require("notes.tasks")

local function progress(list, width)
  local per = {}
  for _, t in ipairs(list) do
    for _, tag in ipairs(t.tags) do
      local p = per[tag] or { done = 0, total = 0 }
      per[tag] = p
      p.total = p.total + 1
      if t.done then p.done = p.done + 1 end
    end
  end
  local names = {}
  for tag in pairs(per) do names[#names + 1] = tag end
  table.sort(names)
  for _, tag in ipairs(names) do
    local p = per[tag]
    local filled = math.floor(p.done / p.total * width + 0.5)
    print(("%-8s [%s%s] %d/%d"):format(tag, ("#"):rep(filled), ("."):rep(width - filled), p.done, p.total))
  end
end

progress(tasks.collect({
  "- [x] a #docs", "- [ ] b #docs", "- [ ] c #docs #ci", "- [x] d #ci", "- [x] e #release",
}), 10)
