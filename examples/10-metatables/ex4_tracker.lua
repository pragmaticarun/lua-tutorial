-- Exercise 4 solution: a proxy that logs every read and write
local function track(t, log)
  return setmetatable({}, {
    __index = function(_, k) log[#log + 1] = "get " .. tostring(k); return t[k] end,
    __newindex = function(_, k, v) log[#log + 1] = "set " .. tostring(k); t[k] = v end,
  })
end
local log = {}
local state = track({ volume = 50 }, log)
state.volume = state.volume + 10
state.muted = true
print(state.volume, state.muted)
print(table.concat(log, ", "))
