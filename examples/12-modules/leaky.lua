-- module
-- leaky.lua: a module that accidentally creates a global
local M = {}
function M.start()
  started_at = 1234                        -- missing 'local': leaks into _G
  return started_at
end
return M
