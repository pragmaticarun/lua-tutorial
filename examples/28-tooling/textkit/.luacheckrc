-- host: luacheck
-- luacheck configuration: also plain Lua.
std = "max"                      -- union of all Lua versions' globals
max_line_length = 100
exclude_files = { ".luarocks", "lua_modules" }

files["spec/"] = { std = "+busted" }   -- describe, it, assert, spy, ...
files["*.rockspec"] = { std = "+rockspec" } -- rockspec fields are globals
files[".busted"] = { std = "max" }
