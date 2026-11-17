-- targets: 5.5, 5.4
-- close_errors.lua: <close> variables run during error unwinding
local function handle(name, log)
  return setmetatable({}, { __close = function(_, err)
    log[#log + 1] = name .. (err and " closed on error" or " closed")
  end })
end
local log = {}
local ok, err = pcall(function()
  local input <close> = handle("input", log)
  local output <close> = handle("output", log)
  error("encode failed", 0)
end)
print(ok, err)
print(table.concat(log, "; "))
