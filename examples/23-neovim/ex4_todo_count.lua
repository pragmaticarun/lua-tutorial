-- host: nvim
-- Exercise 4: extend todo.nvim with todo.count(buf) and a :TodoCount command
-- that prints "FIXME=1 TODO=2" (sorted), without editing the plugin's files.
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end

vim.opt.rtp:prepend(vim.fn.fnamemodify("todo.nvim", ":p"))
local todo = require("todo")
todo.setup({ auto = false })

function todo.count(buf)
  local counts = {}
  for _, it in ipairs(todo.scan(buf or 0)) do
    counts[it.keyword] = (counts[it.keyword] or 0) + 1
  end
  return counts
end

vim.api.nvim_create_user_command("TodoCount", function()
  local counts, parts = todo.count(0), {}
  for kw, n in pairs(counts) do parts[#parts + 1] = kw .. "=" .. n end
  table.sort(parts)
  say(#parts > 0 and table.concat(parts, " ") or "no keywords")
end, {})

vim.api.nvim_buf_set_lines(0, 0, -1, true,
  { "-- TODO: a", "-- FIXME: b", "x() -- TODO: c", "-- todo: lowercase is ignored" })
vim.cmd("TodoCount")
vim.api.nvim_buf_set_lines(0, 0, -1, true, { "clean" })
vim.cmd("TodoCount")
