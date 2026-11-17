-- preload.lua: package.preload registers modules without files (hosts use this)
package.preload["app.config"] = function(name)
  print("building " .. name)
  return { width = 1280, height = 720 }
end
local cfg = require("app.config")
print(cfg.width, cfg.height, require("app.config") == cfg)
