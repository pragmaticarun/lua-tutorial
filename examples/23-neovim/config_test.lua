-- host: nvim
-- Load config/init.lua the way Neovim would, then check what it set up.
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end

-- Neovim puts ~/.config/nvim on 'runtimepath' and sources init.lua; do the same
-- with the example directory (nvim --clean skipped the real user config).
-- remember Neovim's built-in default mappings so we can list only ours
local function keymap_set()
  local set = {}
  for _, mode in ipairs({ "n", "x" }) do
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do set[mode .. m.lhs] = m end
  end
  return set
end
local before = keymap_set()

local cfg = vim.fn.fnamemodify("config", ":p")
vim.opt.rtp:prepend(cfg)
dofile(cfg .. "init.lua")

say("leader:", vim.inspect(vim.g.mapleader))
say("number/relativenumber:", vim.o.number, vim.o.relativenumber)
say("shiftwidth/expandtab:", vim.o.shiftwidth, vim.o.expandtab)
say("listchars:", vim.o.listchars)
say("completeopt:", vim.o.completeopt)
say("shortmess has I:", vim.o.shortmess:find("I", 1, true) ~= nil)

-- the mappings the config added, sorted
local maps = {}
for key, m in pairs(keymap_set()) do
  if not before[key] or before[key].desc ~= m.desc then  -- new or overridden
    maps[#maps + 1] = ("%s %-10s %s"):format(m.mode, (m.lhs:gsub("^ ", "<leader>")), m.desc)
  end
end
table.sort(maps)
for _, m in ipairs(maps) do say(m) end

-- the toggle mapping really toggles
vim.api.nvim_feedkeys(vim.keycode("<leader>tn"), "xt", false)
say("relativenumber after <leader>tn:", vim.wo.relativenumber)

-- FileType autocommand: a Lua buffer gets 2-space indentation
local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(buf)
vim.bo.filetype = "lua"
say("lua buffer shiftwidth:", vim.bo.shiftwidth, "global:", vim.go.shiftwidth)
say("user autocmds:", #vim.api.nvim_get_autocmds({ group = "user" }))
