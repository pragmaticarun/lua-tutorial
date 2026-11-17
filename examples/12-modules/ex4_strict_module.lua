-- targets: 5.5
-- Exercise 4 solution: a module body that cannot leak globals (Lua 5.5)
local src = [[
global<const> *          -- read any global, assign none
local M = {}
function M.start()
  started_at = 1234      -- compile error instead of a silent leak
end
return M
]]
print(load(src, "=leaky.lua"))
local fixed = src:gsub("started_at = 1234", "local started_at = 1234")
print(type(load(fixed, "=fixed.lua")()))
