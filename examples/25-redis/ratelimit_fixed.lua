-- host: redis
-- Fixed-window rate limiter.  KEYS[1] = counter key (e.g. "rl:{user42}:60")
-- ARGV[1] = limit, ARGV[2] = window in seconds.
-- Returns { allowed (1/0), requests seen in this window, ms until reset }.
-- INCR and EXPIRE run as one atomic unit: no other command can slip in
-- between them, which is the whole point of doing this in a script.
local limit = tonumber(ARGV[1])
local window = tonumber(ARGV[2])

local count = redis.call("INCR", KEYS[1])
if count == 1 then
  redis.call("EXPIRE", KEYS[1], window)   -- first hit starts the window
end
local ttl = redis.call("PTTL", KEYS[1])
if count > limit then
  return { 0, count, ttl }
end
return { 1, count, ttl }
