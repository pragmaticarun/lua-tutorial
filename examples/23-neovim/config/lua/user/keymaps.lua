-- module
local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write buffer" })
map({ "n", "x" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
-- move selected lines and keep the selection
map("x", "J", ":move '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
map("x", "K", ":move '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
-- window navigation
for _, key in ipairs({ "h", "j", "k", "l" }) do
  map("n", "<C-" .. key .. ">", "<C-w>" .. key, { desc = "Window " .. key })
end
-- toggle an option with a Lua function
map("n", "<leader>tn", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative numbers" })
