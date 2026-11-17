-- host: stylua
local config = require("config")
local function greet(name) if not name then return "hello, stranger" end return "hello, " .. name end
print(greet("ann"), config.load({ path = "settings.toml", strict = true, defaults = { color = "auto" } }))
-- stylua: ignore
local matrix = {
  1, 0, 0,
  0, 1, 0,
  0, 0, 1,
}
