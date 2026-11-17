-- host: nvim
-- Exercise 2: trim trailing whitespace on save, keep the cursor where it was,
-- and skip markdown (where two trailing spaces mean a line break).
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("trim", { clear = true }),
  callback = function(args)
    if vim.bo[args.buf].filetype == "markdown" then return end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

local dir = vim.fn.tempname(); vim.fn.mkdir(dir, "p")
local function edit_and_save(name, lines)
  vim.cmd.edit(dir .. "/" .. name)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)
  vim.api.nvim_win_set_cursor(0, { 2, 3 })
  vim.cmd("silent write")
  local f = assert(io.open(dir .. "/" .. name, "rb")); local s = f:read("a"); f:close()
  say(name, vim.inspect(s), "cursor", vim.inspect(vim.api.nvim_win_get_cursor(0)))
end
edit_and_save("code.lua", { "local a = 1   ", "return a\t", "" })
edit_and_save("notes.md", { "line one  ", "line two  " })
say("search history untouched:", vim.fn.histget("search", -1) == "")
vim.fn.delete(dir, "rf")
