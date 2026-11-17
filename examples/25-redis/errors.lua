-- host: redis
-- redis.call raises a Lua error on a failed command (the script aborts);
-- redis.pcall returns the error as a table { err = "..." } instead.
local mode = ARGV[1]
redis.call("SET", KEYS[1], "not a number")

if mode == "call" then
  redis.call("INCR", KEYS[1])                 -- error: aborts the script here
  return "unreachable"
elseif mode == "pcall" then
  local res = redis.pcall("INCR", KEYS[1])
  if type(res) == "table" and res.err then
    return "recovered: " .. res.err
  end
elseif mode == "raise" then
  -- error tables become error replies; the first word is the error code
  return error({ err = "INVENTORY_LOW only 2 left" })
elseif mode == "global" then
  counter = 1                                 -- scripts may not create globals
elseif mode == "lua_error" then
  local t = nil
  return t.field                              -- a plain Lua runtime error
end
