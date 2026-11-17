-- host: redis
-- How Lua values become Redis replies (RESP2). ARGV[1] picks a case.
local cases = {
  integer = function() return 42 end,
  float   = function() return 3.99 end,            -- truncated to integer 3!
  float_s = function() return tostring(3.99) end,  -- send floats as strings
  ["true"]  = function() return true end,           -- integer 1
  ["false"] = function() return false end,          -- nil reply
  ["nil"]   = function() return nil end,            -- nil reply
  array   = function() return { 1, "two", { 3, 4 } } end,
  holes   = function() return { 1, 2, nil, 4 } end, -- stops at the first nil
  map     = function() return { a = 1, b = 2 } end, -- non-array keys dropped: empty array
  status  = function() return redis.status_reply("ALL GOOD") end,
  err     = function() return redis.error_reply("BADTHING went wrong") end,
}
-- And the other way: replies of redis.call become Lua values.
-- (A demo shortcut: real scripts must pass every key name in KEYS.)
cases.from_redis = function()
  redis.call("SET", "n", "10")
  redis.call("RPUSH", "l", "x", "y")
  local n = redis.call("INCR", "n")            -- integer reply -> Lua number
  local s = redis.call("GET", "n")             -- bulk string  -> Lua string
  local missing = redis.call("GET", "nope")    -- nil bulk     -> false (not nil!)
  local ok = redis.call("SET", "k", "v")       -- status reply -> { ok = "OK" }
  local list = redis.call("LRANGE", "l", 0, -1)
  return { type(n), type(s), tostring(missing), type(ok) .. ":" .. ok.ok, #list }
end
return cases[ARGV[1]]()
