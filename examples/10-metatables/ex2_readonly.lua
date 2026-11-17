-- Exercise 2 solution: a read-only view of a table
local function readonly(t)
  return setmetatable({}, {
    __index = t,
    __newindex = function(_, k) error("attempt to modify read-only field '" .. tostring(k) .. "'", 2) end,
    __metatable = false,                  -- hide the metatable, block setmetatable
  })
end
local SAMPLE_RATES = readonly { cd = 44100, dvd = 48000 }
print(SAMPLE_RATES.cd, SAMPLE_RATES.dvd)
print(pcall(function() SAMPLE_RATES.cd = 1 end))
print(getmetatable(SAMPLE_RATES))
