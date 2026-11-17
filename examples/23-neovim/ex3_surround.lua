-- host: nvim
-- Exercise 3: <leader>" wraps the word under the cursor in quotes using
-- nvim_buf_set_text (two inserts, right side first so columns stay valid).
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end
vim.g.mapleader = " "

local function surround_word(left, right)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))  -- row 1-based, col 0-based
  local line = vim.api.nvim_get_current_line()
  -- find the [s, e] (1-based, inclusive) extent of the word containing col+1
  local s, e = col + 1, col + 1
  if not line:sub(s, s):match("[%w_]") then return false end
  while s > 1 and line:sub(s - 1, s - 1):match("[%w_]") do s = s - 1 end
  while e < #line and line:sub(e + 1, e + 1):match("[%w_]") do e = e + 1 end
  vim.api.nvim_buf_set_text(0, row - 1, e, row - 1, e, { right })
  vim.api.nvim_buf_set_text(0, row - 1, s - 1, row - 1, s - 1, { left })
  return true
end

vim.keymap.set("n", '<leader>"', function() surround_word('"', '"') end)
vim.keymap.set("n", "<leader>(", function() surround_word("(", ")") end)

vim.api.nvim_buf_set_lines(0, 0, -1, true, { "print hello world", "x = y + z" })
vim.api.nvim_win_set_cursor(0, { 1, 8 })                -- inside "hello"
vim.api.nvim_feedkeys(vim.keycode('<leader>"'), "xt", false)
vim.api.nvim_win_set_cursor(0, { 2, 4 })                -- on "y"
vim.api.nvim_feedkeys(vim.keycode("<leader>("), "xt", false)
for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, true)) do say(l) end
vim.api.nvim_win_set_cursor(0, { 2, 1 })                -- on a space
say("on a space:", surround_word("[", "]"))
