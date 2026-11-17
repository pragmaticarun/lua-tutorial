-- module
-- plugin/*.lua is sourced automatically at startup for every plugin on
-- 'runtimepath'. Keep it tiny: define commands, and require the real code
-- lazily so startup stays fast.
if vim.g.loaded_todo then return end
vim.g.loaded_todo = true

vim.api.nvim_create_user_command("TodoQuickfix", function()
  require("todo").to_quickfix()
end, { desc = "List TODO/FIXME comments of all buffers in the quickfix list" })

vim.api.nvim_create_user_command("TodoHighlight", function(opts)
  require("todo").highlight(0, opts.bang)
end, { bang = true, desc = "Highlight keywords in this buffer (! clears)" })
