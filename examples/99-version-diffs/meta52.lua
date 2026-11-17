-- meta52.lua: __len and __pairs on tables (Lua 5.2+ semantics)
local proxy = setmetatable({}, {
  __len = function() return 42 end,
  __pairs = function(t)
    return function(_, k) if k == nil then return "only", "entry" end end, t, nil
  end,
})
print("#proxy:", #proxy)
for k, v in pairs(proxy) do print("pairs:", k, v) end
