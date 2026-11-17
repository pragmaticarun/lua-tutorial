-- host: luacheck
-- Exercise 3: code that is fine for its environment, configured rather
-- than "fixed": APP is a global the host provides, vim is read-only,
-- and unused `self` arguments are expected in methods.
local Widget = {}
Widget.__index = Widget

function Widget.new(name) return setmetatable({ name = name }, Widget) end

function Widget:kind() return "widget" end   -- self unused: W212, ignored by config

function Widget:render()
  APP.render_count = (APP.render_count or 0) + 1
  return vim.fn.toupper(self.name)
end

local debug_only = true -- luacheck: ignore 211

return Widget
