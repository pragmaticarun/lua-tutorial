-- module
-- ~/.config/nvim/init.lua -- the entry point Neovim runs at startup.
-- ~/.config/nvim is on 'runtimepath', so require("user.options") finds
-- ~/.config/nvim/lua/user/options.lua.
vim.g.mapleader = " "        -- set before any mapping that uses <leader>
vim.g.maplocalleader = ","

require("user.options")
require("user.keymaps")
require("user.autocmds")
