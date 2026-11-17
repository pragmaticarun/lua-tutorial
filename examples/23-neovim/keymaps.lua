-- host: nvim
-- vim.keymap.set: Lua callbacks, buffer-local maps, expr maps, and how to test them.
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end

vim.g.mapleader = " "
local log = {}

-- a normal-mode mapping to a Lua function; desc shows up in :map and pickers
vim.keymap.set("n", "<leader>w", function() table.insert(log, "save!") end,
  { desc = "Pretend to save" })

-- a mapping to keys (a string rhs); `silent` hides the command line echo
vim.keymap.set("n", "<leader>d", "dd", { silent = true, desc = "Delete line" })

-- expr mapping: the function returns the keys to run
vim.keymap.set("n", "<leader>j", function()
  return vim.v.count > 0 and "j" or "gg"
end, { expr = true })

-- buffer-local mapping: exists only in this buffer
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "one", "two", "three" })
vim.keymap.set("n", "<leader>u", function()
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line(line:upper())
end, { buffer = buf, desc = "Uppercase line" })

-- feedkeys with "x" executes immediately, as if typed ("t" = remappable)
local function type_keys(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "xt", false)
end

type_keys("<leader>w")
say("log:", table.concat(log, ","))

vim.api.nvim_win_set_cursor(0, { 2, 0 })
type_keys("<leader>u")
say("after <leader>u:", table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, true), ","))

type_keys("<leader>d")
say("after <leader>d:", table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, true), ","))

type_keys("<leader>j")
say("cursor after <leader>j:", vim.api.nvim_win_get_cursor(0)[1])

-- inspecting mappings
local m = vim.fn.maparg("<leader>w", "n", false, true)
say("maparg desc:", m.desc, "lua callback:", type(m.callback))
for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
  say("buffer map:", map.lhs:gsub(" ", "<Space>"), map.desc)
end

-- removing a mapping
vim.keymap.del("n", "<leader>w")
say("deleted:", vim.fn.maparg("<leader>w", "n") == "")
