-- module
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.expandtab = true          -- spaces, not tabs
opt.shiftwidth = 4
opt.tabstop = 4
opt.ignorecase = true
opt.smartcase = true          -- case-sensitive if the pattern has capitals
opt.undofile = true
opt.splitright = true
opt.scrolloff = 5
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.completeopt = { "menuone", "noselect" }
opt.shortmess:append("I")     -- list options: append/remove/prepend
