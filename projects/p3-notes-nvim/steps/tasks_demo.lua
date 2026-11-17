-- notes.tasks has no vim.* calls, so plain Lua can test it: Lua 5.5, 5.4 and
-- LuaJIT (Neovim's own Lua) all give the same output.
package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path
local tasks = require("notes.tasks")

local lines = {
  "# Notes",
  "- [ ] write the release notes #docs @2026-11-20",
  "  - [x] draft #docs",
  "* [ ] fix the build #ci @2026-11-10",
  "- [] not a task (no space in the box)",
  "- [ ] tidy the README #docs",
}
local list = tasks.collect(lines)
print(tasks.summary(list))
for _, t in ipairs(tasks.sort(list)) do
  print(("line %d  indent %d  due %-10s tags %-5s  %s"):format(
    t.lnum, t.indent, tostring(t.due), table.concat(t.tags, ","), tasks.format(t, "2026-11-17")))
end
print(#tasks.filter(list, { "docs" }), #tasks.filter(list, { "docs", "ci" }))
print(tasks.toggle(lines[2]))
print(tasks.toggle(lines[3]))
print(tasks.toggle("- [ ] keep [ ] this"))
