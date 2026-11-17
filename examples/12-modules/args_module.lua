-- module
-- args_module.lua: what does require pass to the module chunk?
local n = select("#", ...)
local name, path = ...
return { n = n, name = name, path = path }
