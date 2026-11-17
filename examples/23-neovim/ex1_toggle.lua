-- host: nvim
-- Exercise 1: a generic option toggler, a :Toggle command with completion,
-- and <leader>t{w,s} mappings built from a table.
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end
vim.g.mapleader = " "

local function toggle(name)
  local info = vim.api.nvim_get_option_info2(name, {})
  assert(info.type == "boolean", name .. " is not a boolean option")
  -- vim.o for global options, vim.wo/vim.bo for window/buffer-local ones
  local scope = info.scope == "win" and vim.wo or info.scope == "buf" and vim.bo or vim.o
  scope[name] = not scope[name]
  return scope[name]
end

vim.api.nvim_create_user_command("Toggle", function(o) say(o.args, "=", toggle(o.args)) end, {
  nargs = 1,
  complete = function() return { "wrap", "spell", "list", "number" } end,
})

for key, opt in pairs({ w = "wrap", s = "spell" }) do
  vim.keymap.set("n", "<leader>t" .. key, function() toggle(opt) end, { desc = "Toggle " .. opt })
end

say("wrap before:", vim.wo.wrap)
vim.api.nvim_feedkeys(vim.keycode("<leader>tw"), "xt", false)
say("wrap after <leader>tw:", vim.wo.wrap)
vim.cmd("Toggle spell")
vim.cmd("Toggle spell")
say("ignorecase toggled:", toggle("ignorecase"))
say("bad option:", select(2, pcall(toggle, "shiftwidth")):match("shiftwidth is not a boolean option"))
