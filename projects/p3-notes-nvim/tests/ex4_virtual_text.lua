-- host: nvim
-- Exercise 4 (solution): show "N open / M" as virtual text after the
-- "## Tasks" heading of any .notes.md buffer, kept up to date as you type.
local function say(s) io.write(s, "\n") end
vim.opt.rtp:prepend(vim.fn.fnamemodify("..", ":p"))
local tasks = require("notes.tasks")
local ns = vim.api.nvim_create_namespace("notes-counts")

local function annotate(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local list = tasks.collect(lines)
  local open = 0
  for _, t in ipairs(list) do if not t.done then open = open + 1 end end
  for i, line in ipairs(lines) do
    if line:match("^##%s+Tasks") then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        virt_text = { { ("  %d open / %d"):format(open, #list), "Comment" } },
        virt_text_pos = "eol",
      })
    end
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
  pattern = "*.notes.md",
  group = vim.api.nvim_create_augroup("notes-counts", { clear = true }),
  callback = function(args) annotate(args.buf) end,
})

-- try it: a notes buffer, then an edit
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
vim.fn.writefile({ "## Tasks", "- [ ] one", "- [x] two" }, dir .. "/.notes.md")
vim.cmd.edit(dir .. "/.notes.md")
local function show()
  local m = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })
  say(("row %d: %s"):format(m[1][2], m[1][4].virt_text[1][1]))
end
show()
vim.api.nvim_buf_set_lines(0, -1, -1, false, { "- [ ] three" })
vim.api.nvim_exec_autocmds("TextChanged", { buffer = 0 })   -- headless: no main loop to fire it
show()
vim.fn.delete(dir, "rf")
