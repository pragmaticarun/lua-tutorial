-- notes.tasks: Markdown task lines, with no Neovim API in sight, so this
-- module also runs (and is tested) on plain Lua 5.5, 5.4 and LuaJIT.
--
--   - [ ] write the release notes #docs @2026-11-20
--   - [x] fix the build #ci
local M = {}

local TASK = "^(%s*)[-*] %[([ xX])%] (.*)$"

--- Parse one line; nil when it is not a task.
function M.parse(line, lnum)
  local indent, mark, text = line:match(TASK)
  if not indent then return nil end
  local tags = {}
  for tag in text:gmatch("#([%w_-]+)") do tags[#tags + 1] = tag end
  return {
    lnum = lnum, indent = #indent, done = mark ~= " ", text = text, tags = tags,
    due = text:match("@(%d%d%d%d%-%d%d%-%d%d)"),
  }
end

--- Every task in a list of lines (1-based line numbers).
function M.collect(lines)
  local out = {}
  for i, line in ipairs(lines) do
    local t = M.parse(line, i)
    if t then out[#out + 1] = t end
  end
  return out
end

--- The same line with its checkbox flipped (other text untouched).
function M.toggle(line)
  return (line:gsub("^(%s*[-*] %[)([ xX])(%])", function(a, mark, b)
    return a .. (mark == " " and "x" or " ") .. b
  end, 1))
end

--- Picker order: open before done, then by due date (undated last), then
--- by position in the file.
function M.sort(tasks)
  table.sort(tasks, function(a, b)
    if a.done ~= b.done then return not a.done end
    if a.due ~= b.due then
      if not a.due then return false end
      if not b.due then return true end
      return a.due < b.due
    end
    return a.lnum < b.lnum
  end)
  return tasks
end

--- Keep tasks that have every tag in `want` (a list); empty list = all.
function M.filter(tasks, want)
  local out = {}
  for _, t in ipairs(tasks) do
    local ok = true
    for _, w in ipairs(want) do
      local found = false
      for _, tag in ipairs(t.tags) do if tag == w then found = true end end
      ok = ok and found
    end
    if ok then out[#out + 1] = t end
  end
  return out
end

--- One picker row: "[x] text   (line 12)", overdue marked with "!".
function M.format(t, today)
  local overdue = not t.done and t.due and today and t.due < today
  return ("%s [%s] %s"):format(overdue and "!" or " ", t.done and "x" or " ", t.text)
end

--- Counts for the window title.
function M.summary(tasks)
  local done = 0
  for _, t in ipairs(tasks) do if t.done then done = done + 1 end end
  return ("%d tasks, %d open"):format(#tasks, #tasks - done)
end

return M
