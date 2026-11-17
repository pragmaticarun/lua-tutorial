-- host: redis
-- Exercise 2: sliding-window log limiter with a sorted set.
-- KEYS[1] = zset, ARGV = limit, window_ms, now_ms, request id.
-- Every accepted request is a member scored by its time; entries older than
-- the window are trimmed first, so the window slides instead of resetting.
local limit, window, now, id = tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3]), ARGV[4]
redis.call("ZREMRANGEBYSCORE", KEYS[1], "-inf", now - window)
local n = redis.call("ZCARD", KEYS[1])
if n >= limit then
  local oldest = redis.call("ZRANGE", KEYS[1], 0, 0, "WITHSCORES")
  return { 0, n, tonumber(oldest[2]) + window - now }   -- retry after (ms)
end
redis.call("ZADD", KEYS[1], now, id)
redis.call("PEXPIRE", KEYS[1], window)
return { 1, n + 1, 0 }
