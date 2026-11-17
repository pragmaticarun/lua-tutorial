-- index_fn.lua: __index as a function computes missing values on demand
local calls = 0
local squares = setmetatable({}, {
  __index = function(t, k)                -- called only when t[k] is absent
    calls = calls + 1
    local v = k * k
    rawset(t, k, v)                       -- cache it: next time no metamethod
    return v
  end,
})
print(squares[12], squares[12], squares[3])
print("metamethod calls:", calls)
