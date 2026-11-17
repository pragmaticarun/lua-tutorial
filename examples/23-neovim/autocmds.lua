-- host: nvim
-- Autocommands: augroups, patterns, callbacks with event data, once, User events.
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end

local api = vim.api
-- An augroup with clear = true makes re-sourcing your config idempotent:
-- the group's old autocommands are deleted before new ones are added.
local group = api.nvim_create_augroup("lesson23", { clear = true })

-- BufNewFile/BufRead for a pattern; args has buf, file, match, event, data
api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = group,
  pattern = "*.todo",
  callback = function(args)
    vim.bo[args.buf].filetype = "todo"
    say(("%s on %s -> filetype=todo"):format(args.event, vim.fs.basename(args.file)))
  end,
})

-- FileType autocommands fire when the filetype option is set
api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "todo",
  callback = function(args)
    vim.bo[args.buf].commentstring = "# %s"
    say("FileType todo: commentstring=" .. vim.bo[args.buf].commentstring)
  end,
})

-- BufWritePre runs before the file is written: a classic "trim on save"
api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = "*.todo",
  callback = function(args)
    local lines = api.nvim_buf_get_lines(args.buf, 0, -1, true)
    for i, l in ipairs(lines) do lines[i] = l:gsub("%s+$", "") end
    api.nvim_buf_set_lines(args.buf, 0, -1, true, lines)
  end,
})

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local path = dir .. "/today.todo"
vim.cmd.edit(vim.fn.fnameescape(path))                  -- fires BufNewFile + FileType
api.nvim_buf_set_lines(0, 0, -1, true, { "buy milk   ", "write lesson 23\t" })
vim.cmd.write()                                         -- fires BufWritePre
local f = assert(io.open(path, "rb"))
say("on disk:", vim.inspect(f:read("a")))
f:close()

-- once = true: the autocommand deletes itself after the first run
local hits = 0
api.nvim_create_autocmd("User", {
  group = group,
  pattern = "LessonPing",
  once = true,
  callback = function(args) hits = hits + 1; say("ping data:", vim.inspect(args.data)) end,
})
-- User events are how plugins announce things; data travels in args.data
api.nvim_exec_autocmds("User", { pattern = "LessonPing", data = { n = 1 } })
api.nvim_exec_autocmds("User", { pattern = "LessonPing", data = { n = 2 } })
say("hits:", hits)

-- returning true from a callback also deletes the autocommand
local seen = 0
api.nvim_create_autocmd("User", {
  group = group,
  pattern = "Countdown",
  callback = function() seen = seen + 1; return seen == 2 end,
})
for _ = 1, 5 do api.nvim_exec_autocmds("User", { pattern = "Countdown" }) end
say("countdown callback ran", seen, "times")

-- listing and clearing
say("autocmds in group:", #api.nvim_get_autocmds({ group = group }))
api.nvim_clear_autocmds({ group = group, event = "BufWritePre" })
say("after clearing BufWritePre:", #api.nvim_get_autocmds({ group = group }))
vim.fn.delete(dir, "rf")
