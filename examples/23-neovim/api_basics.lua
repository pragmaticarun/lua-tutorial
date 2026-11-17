-- host: nvim
-- Run with: nvim --headless --clean -l api_basics.lua
-- Buffers, lines, options and Vimscript functions through vim.api / vim.fn.
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end

local api = vim.api

-- a scratch buffer: not listed, no file behind it
local buf = api.nvim_create_buf(false, true)
api.nvim_set_current_buf(buf)
api.nvim_buf_set_lines(buf, 0, -1, true, { "local x = 1", "-- TODO: rename x", "return x" })

say("lines:", api.nvim_buf_line_count(buf))
say("line 2:", api.nvim_buf_get_lines(buf, 1, 2, true)[1])

-- 0-based, end-exclusive ranges; replace line 1, insert after line 3
api.nvim_buf_set_lines(buf, 0, 1, true, { "local count = 1" })
api.nvim_buf_set_lines(buf, 3, 3, true, { "-- end" })
say(table.concat(api.nvim_buf_get_lines(buf, 0, -1, true), " | "))

-- text edits inside a line: (row, col) are 0-based, byte offsets
api.nvim_buf_set_text(buf, 2, 7, 2, 8, { "count" })
say("line 3:", api.nvim_buf_get_lines(buf, 2, 3, true)[1])

-- options: vim.o (global), vim.bo (buffer), vim.wo (window), vim.opt (list-aware)
vim.bo[buf].filetype = "lua"
vim.bo[buf].shiftwidth = 2
vim.o.ignorecase = true
vim.opt.wildignore = { "*.o", "*.so" }
vim.opt.wildignore:append("*.a")
say("filetype:", vim.bo[buf].filetype, "sw:", vim.bo.shiftwidth)
say("wildignore:", vim.o.wildignore)

-- the cursor: (1-based row, 0-based col)
api.nvim_win_set_cursor(0, { 2, 6 })
say("cursor:", vim.inspect(api.nvim_win_get_cursor(0)))

-- Vimscript functions are available through vim.fn, Ex commands through vim.cmd
say("strlen:", vim.fn.strlen("héllo"), "toupper:", vim.fn.toupper("abc"))
vim.cmd("%s/count/total/g")
say(table.concat(api.nvim_buf_get_lines(buf, 0, -1, true), " | "))

-- buffer-scoped variables (b:), global variables (g:)
vim.b[buf].reviewed = true
vim.g.my_plugin_loaded = 1
say("b:reviewed =", vim.b.reviewed, "g:my_plugin_loaded =", vim.fn.eval("g:my_plugin_loaded"))

-- vim.inspect, vim.tbl_* and vim.split are handy pure-Lua helpers
say(vim.inspect(vim.split("a,b,,c", ",", { plain = true })))
say(vim.inspect(vim.tbl_deep_extend("force", { a = { x = 1, y = 2 } }, { a = { y = 3 } })))
