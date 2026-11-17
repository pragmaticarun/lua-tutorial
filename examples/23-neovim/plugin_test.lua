-- host: nvim
-- Test the todo.nvim plugin in a real Neovim: load it from 'runtimepath' the
-- way a plugin manager would, then drive its commands and API.
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end
local function check(cond, msg) assert(cond, msg); say("ok - " .. msg) end

vim.opt.rtp:prepend(vim.fn.fnamemodify("todo.nvim", ":p"))
vim.cmd.runtime({ "plugin/todo.lua", bang = true })   -- what startup does

check(vim.g.loaded_todo == true, "plugin/todo.lua was sourced")
check(vim.fn.exists(":TodoQuickfix") == 2, ":TodoQuickfix exists")
check(package.loaded["todo"] == nil, "lua/todo is not loaded until first use")

local todo = require("todo")
todo.setup({ keywords = { HACK = "WarningMsg" } })   -- adds to the defaults
check(todo.config.keywords.TODO == "Todo" and todo.config.keywords.HACK == "WarningMsg",
  "setup() deep-merges user options over defaults")

local function new_buf(name, lines)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  return buf
end
local a = new_buf("a.lua", { "local x = 1 -- TODO: rename", "-- NOTE: fine", "TODOS: not a match" })
local b = new_buf("b.lua", { "-- FIXME: leaks memory", "-- HACK: temporary" })

-- the BufEnter autocommand from setup() highlights on entering a buffer
vim.api.nvim_set_current_buf(a)
local marks = vim.api.nvim_buf_get_extmarks(a, todo.ns, 0, -1, { details = true })
check(#marks == 2, "BufEnter highlighted 2 keywords in a.lua")
say(("   first mark: row %d col %d-%d %s"):format(marks[1][2], marks[1][3],
  marks[1][4].end_col, marks[1][4].hl_group))

vim.cmd("TodoHighlight!")
check(#vim.api.nvim_buf_get_extmarks(a, todo.ns, 0, -1, {}) == 0, ":TodoHighlight! clears")

vim.cmd("TodoQuickfix")
local qf = vim.fn.getqflist({ title = 1, items = 1 })
check(qf.title == "TODOs" and #qf.items == 4, ":TodoQuickfix found 4 items")
for _, it in ipairs(qf.items) do
  say(("   %s:%d:%d [%s] %s"):format(vim.fs.basename(vim.api.nvim_buf_get_name(it.bufnr)),
    it.lnum, it.col, it.type, it.text))
end

-- TextChanged is not fired by API edits in headless mode; fire it explicitly
vim.api.nvim_set_current_buf(b)
vim.api.nvim_buf_set_lines(b, -1, -1, true, { "-- TODO: one more" })
vim.api.nvim_exec_autocmds("TextChanged", { buffer = b })
check(#vim.api.nvim_buf_get_extmarks(b, todo.ns, 0, -1, {}) == 3, "TextChanged re-highlighted b.lua")

todo.setup({ auto = false })
check(#vim.api.nvim_get_autocmds({ group = "todo" }) == 0, "setup({auto=false}) removed the autocmds")
