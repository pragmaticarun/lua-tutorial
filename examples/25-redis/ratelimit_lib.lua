#!lua name=ratelimit
-- host: redis
-- A Redis Functions library (Redis 7+). Unlike EVAL scripts, functions are
-- named, stored with the dataset (persisted and replicated), and loaded once
-- with FUNCTION LOAD. The first line (the shebang) names the engine and library.

local function fixed_window(keys, args)
  local limit, window = tonumber(args[1]), tonumber(args[2])
  local count = redis.call("INCR", keys[1])
  if count == 1 then redis.call("EXPIRE", keys[1], window) end
  return count <= limit and 1 or 0
end

-- read-only: how many requests were seen in the current window
local function peek(keys)
  return tonumber(redis.call("GET", keys[1]) or "0")
end

local function reset(keys)
  return redis.call("DEL", keys[1])
end

redis.register_function("rl_hit", fixed_window)
redis.register_function{
  function_name = "rl_peek",
  callback = peek,
  flags = { "no-writes" },   -- allowed in FCALL_RO and on read-only replicas
  description = "requests seen in the current window",
}
redis.register_function("rl_reset", reset)
