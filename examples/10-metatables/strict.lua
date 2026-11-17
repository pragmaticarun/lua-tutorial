-- strict.lua: __index/__newindex to catch misspelled fields
local function strict(fields)
  local data = {}
  for k, v in pairs(fields) do data[k] = v end
  return setmetatable({}, {               -- an empty proxy: every access is a miss
    __index = function(_, k)
      if data[k] == nil then error("unknown field '" .. tostring(k) .. "'", 2) end
      return data[k]
    end,
    __newindex = function(_, k, v)
      if data[k] == nil then error("cannot add field '" .. tostring(k) .. "'", 2) end
      data[k] = v
    end,
  })
end
local cfg = strict { width = 1920, height = 1080 }
cfg.width = 1280
print(cfg.width, cfg.height)
print(pcall(function() return cfg.widht end))
print(pcall(function() cfg.depth = 8 end))
