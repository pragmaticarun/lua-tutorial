-- leak_check.lua: detect modules that create globals
package.path = "./?.lua;" .. package.path
local before = {}
for k in pairs(_G) do before[k] = true end
require("leaky").start()
for k in pairs(_G) do
  if not before[k] then print("new global:", k) end
end
