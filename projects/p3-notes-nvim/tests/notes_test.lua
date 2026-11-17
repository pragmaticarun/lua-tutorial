-- host: nvim
-- notes.nvim in a real, headless Neovim: run with  nvim --headless --clean -l notes_test.lua
-- (from tests/). print() goes to the message area (stderr) under -l, so the
-- test writes its report to stdout with io.write.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end
local function check(cond, msg)
  if not cond then error("FAILED: " .. msg, 2) end
  say("ok - " .. msg)
end
local function keys(k)       -- type keys as a user would; "x" = execute now
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(k, true, false, true), "mx", false)
end

-- a throw-away project: a .git directory marks its root
local root = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(root .. "/.git", "p")
vim.fn.mkdir(root .. "/src", "p")
local function show_file()
  for _, l in ipairs(vim.fn.readfile(root .. "/.notes.md")) do say("   | " .. l) end
end

-- install the plugin the way a plugin manager does: add it to 'runtimepath'
vim.opt.rtp:prepend(vim.fn.fnamemodify("..", ":p"))
vim.cmd.runtime({ "plugin/notes.lua", bang = true })
check(vim.fn.exists(":Tasks") == 2 and vim.fn.exists(":NoteAdd") == 2, "commands defined at startup")
check(package.loaded["notes"] == nil, "lua/notes not loaded until a command runs")

require("notes").setup({ today = function() return "2026-11-17" end })   -- a fixed "today"
vim.cmd.edit(root .. "/src/main.c")
check(require("notes").root() == root, "root found from src/main.c via .git")

vim.cmd("NoteAdd write the release notes #docs @2026-11-20")
vim.cmd("NoteAdd fix the build #ci @2026-11-10")
vim.cmd("NoteAdd tidy the README #docs")
check(vim.fn.filereadable(root .. "/.notes.md") == 1, ":NoteAdd created .notes.md")
show_file()
check(vim.deep_equal(vim.fn.getcompletion("Tasks d", "cmdline"), { "docs" }), ":Tasks completes tags")

-- the picker
vim.cmd("Tasks")
local win = vim.api.nvim_get_current_win()
local cfg = vim.api.nvim_win_get_config(win)
check(cfg.relative == "editor", "picker is a floating window")
say("   title: " .. cfg.title[1][1])
local buf = vim.api.nvim_win_get_buf(win)
for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do say("   > " .. l) end
local marks = vim.api.nvim_buf_get_extmarks(buf, require("notes").ns, 0, -1, { details = true })
local groups = {}
for _, m in ipairs(marks) do groups[#groups + 1] = m[4].hl_group end
say("   highlights: " .. table.concat(groups, " "))
check(vim.bo[buf].modifiable == false, "picker buffer is read-only")

keys("<CR>")                        -- toggle the first (overdue) task
check(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "  [x] fix the build #ci @2026-11-10",
  "<CR> marked it done in the picker")
say("   title: " .. vim.api.nvim_win_get_config(win).title[1][1])
show_file()
keys("q")
check(not vim.api.nvim_win_is_valid(win), "q closed the picker")

vim.cmd("Tasks docs")
win = vim.api.nvim_get_current_win()
buf = vim.api.nvim_win_get_buf(win)
check(#vim.api.nvim_buf_get_lines(buf, 0, -1, false) == 2, ":Tasks docs shows the 2 #docs tasks")
keys("j")
keys("o")                           -- open the notes at the second #docs task
local nwin = vim.api.nvim_get_current_win()
check(vim.api.nvim_buf_get_name(0) == root .. "/.notes.md", "o opened the notes file in a float")
check(vim.api.nvim_win_get_cursor(nwin)[1] == 5, "cursor on that task's line (5)")

-- edit the open buffer, then add a task: it goes through the buffer and saves
vim.api.nvim_buf_set_lines(0, 0, 0, false, { "# Project notes", "" })
vim.cmd("NoteAdd ship it #release")
check(not vim.bo.modified, "buffer saved after :NoteAdd")
show_file()
keys("q")

-- :checkhealth runs in its own buffer, which has no file: the root then
-- comes from the working directory
vim.fn.chdir(root .. "/src")
vim.cmd("checkhealth notes")
for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
  if l:find("OK") or l:find("WARN") or l:find("root") then
    say("   health: " .. vim.trim((l:gsub(vim.pesc(root), "<root>"))))
  end
end
vim.fn.chdir("/")
vim.fn.delete(root, "rf")
say("all notes.nvim tests passed")
