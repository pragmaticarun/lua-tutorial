-- host: luacheck
std = "lua51"
globals = { "APP" }          -- may be read and written
read_globals = { "vim" }     -- read-only: reading vim.fn is fine, assigning vim.x is not
ignore = { "212/self" }      -- unused argument named self
