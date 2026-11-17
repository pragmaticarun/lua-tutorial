-- notes.nvim: one Markdown notes file per project, and a floating picker for
-- the tasks in it. require("notes") is loaded on first use of a command.
local tasks = require("notes.tasks")

local M = {}

local defaults = {
  file = ".notes.md",                   -- relative to the project root
  root_markers = { ".git", ".notes.md" },
  width = 0.6, height = 0.5,            -- fractions of the editor size
  border = "rounded",
  today = function() return os.date("%Y-%m-%d") end,
}
M.config = vim.deepcopy(defaults)
M.ns = vim.api.nvim_create_namespace("notes")

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

--- The project root: the nearest directory above the current buffer (or the
--- working directory) that has one of the markers.
function M.root()
  return vim.fs.root(0, M.config.root_markers) or vim.uv.cwd()
end

function M.path()
  return vim.fs.joinpath(M.root(), M.config.file)
end

-- If the notes file is open in a buffer, that buffer is the truth (it may
-- have unsaved edits); otherwise the file on disk.
-- (path defaults to the current project's notes file; the picker passes the
-- path it was opened for, because its own scratch buffer has no project)
local function notes_buf(path)
  local buf = vim.fn.bufnr(path)
  if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then return buf end
end

function M.read(path)
  path = path or M.path()
  local buf = notes_buf(path)
  if buf then return vim.api.nvim_buf_get_lines(buf, 0, -1, false) end
  if vim.uv.fs_stat(path) then return vim.fn.readfile(path) end
  return {}
end

function M.write(lines, path)
  path = path or M.path()
  local buf = notes_buf(path)
  if buf then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_call(buf, function() vim.cmd("silent noautocmd write") end)
  else
    vim.fn.writefile(lines, path)
  end
end

--- Append "- [ ] text" to the "## Tasks" section (created if missing).
function M.add_task(text)
  local lines = M.read()
  local header, last
  for i, line in ipairs(lines) do
    if line:match("^##%s+Tasks%s*$") then header = i
    elseif header and line:match("^#") then break        -- next section
    elseif header and tasks.parse(line, i) then last = i end
  end
  local entry = "- [ ] " .. vim.trim(text)
  if not header then
    if #lines > 0 and lines[#lines] ~= "" then lines[#lines + 1] = "" end
    vim.list_extend(lines, { "## Tasks", "", entry })
  else
    table.insert(lines, (last or header + 1) + 1, entry)
    if not last and lines[header + 1] ~= "" then table.insert(lines, header + 1, "") end
  end
  M.write(lines)
  vim.notify("notes: added " .. entry, vim.log.levels.INFO)
end

--- Every #tag used in the notes, sorted.
function M.tags()
  local seen, out = {}, {}
  for _, t in ipairs(tasks.collect(M.read())) do
    for _, tag in ipairs(t.tags) do
      if not seen[tag] then seen[tag] = true; out[#out + 1] = tag end
    end
  end
  table.sort(out)
  return out
end

-- a centred floating window for buffer `buf`
local function float(buf, title)
  local w = math.floor(vim.o.columns * M.config.width)
  local h = math.floor(vim.o.lines * M.config.height)
  return vim.api.nvim_open_win(buf, true, {
    relative = "editor", width = w, height = h,
    row = math.floor((vim.o.lines - h) / 2), col = math.floor((vim.o.columns - w) / 2),
    border = M.config.border, title = title, title_pos = "center", style = "minimal",
  })
end

--- Open the notes file itself in a float. It is a normal file buffer, so
--- :w saves it; q closes the window.
function M.open(lnum, path)
  path = path or M.path()
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  vim.bo[buf].buflisted = true
  local win = float(buf, " notes: " .. vim.fs.basename(vim.fs.dirname(path)) .. " ")
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close notes" })
  if lnum then vim.api.nvim_win_set_cursor(win, { lnum, 0 }) end
  return win, buf
end

--- The task picker: <CR> toggles, o opens the notes at the task, q closes.
function M.pick(want)
  local path = M.path()                                  -- fixed before we switch windows
  local list = tasks.sort(tasks.filter(tasks.collect(M.read(path)), want or {}))
  local buf = vim.api.nvim_create_buf(false, true)       -- unlisted scratch buffer
  vim.bo[buf].bufhidden = "wipe"
  local today = M.config.today()

  local function render()
    local rows = {}
    for i, t in ipairs(list) do rows[i] = tasks.format(t, today) end
    if #rows == 0 then rows = { "  (no tasks)" } end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, rows)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
    for i, t in ipairs(list) do
      local group = t.done and "Comment" or (rows[i]:sub(1, 1) == "!" and "DiagnosticError" or nil)
      if group then
        vim.api.nvim_buf_set_extmark(buf, M.ns, i - 1, 0, { end_col = #rows[i], hl_group = group })
      end
      for s, e in rows[i]:gmatch("()#[%w_-]+()") do      -- tags
        vim.api.nvim_buf_set_extmark(buf, M.ns, i - 1, s - 1, { end_col = e - 1, hl_group = "Special" })
      end
    end
  end
  render()
  local win = float(buf, " " .. tasks.summary(list) .. " ")

  local function current() return list[vim.api.nvim_win_get_cursor(win)[1]] end
  local map = function(lhs, fn, desc) vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc }) end
  map("<CR>", function()
    local t = current()
    if not t then return end
    local lines = M.read(path)
    lines[t.lnum] = tasks.toggle(lines[t.lnum])
    M.write(lines, path)
    t.done = not t.done
    render()
    vim.api.nvim_win_set_config(win, { title = " " .. tasks.summary(list) .. " ", title_pos = "center" })
  end, "Toggle task")
  map("o", function()
    local t = current()
    vim.api.nvim_win_close(win, true)
    if t then M.open(t.lnum, path) end
  end, "Open notes at task")
  map("q", function() vim.api.nvim_win_close(win, true) end, "Close")
  map("<Esc>", function() vim.api.nvim_win_close(win, true) end, "Close")
  return win, buf, list
end

return M
