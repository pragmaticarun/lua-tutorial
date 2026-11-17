-- :checkhealth notes  runs this check().
local M = {}

function M.check()
  local notes = require("notes")
  vim.health.start("notes.nvim")
  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim " .. tostring(vim.version()))
  else
    vim.health.error("needs Neovim 0.10 or newer (vim.fs.root, vim.uv)")
  end
  vim.health.info("project root: " .. notes.root())
  local path = notes.path()
  if vim.uv.fs_stat(path) then
    vim.health.ok(("notes file: %s (%d tasks)"):format(path, #require("notes.tasks").collect(notes.read())))
  else
    vim.health.warn("no notes file yet: " .. path, { "Run :NoteAdd or :Notes to create it" })
  end
end

return M
