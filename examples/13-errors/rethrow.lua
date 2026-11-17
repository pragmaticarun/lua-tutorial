-- rethrow.lua: clean up, then propagate the original error unchanged
local log = {}
local function with_lock(fn)
  log[#log + 1] = "lock"
  local ok, err = pcall(fn)
  log[#log + 1] = "unlock"                   -- always runs
  if not ok then error(err, 0) end           -- level 0: don't add a 2nd position
  return err
end
print(pcall(with_lock, function() error("write failed") end))
print(table.concat(log, ","))
