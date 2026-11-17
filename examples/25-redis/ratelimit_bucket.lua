-- host: redis
-- Token bucket: smooth rate limiting with bursts.
-- KEYS[1] = bucket hash.  ARGV: capacity, refill tokens per second, now in ms,
-- cost of this request.  Returns { allowed (1/0), tokens left (as a string) }.
-- "now" is passed in so tests are reproducible; production code can use
-- redis.call("TIME") instead (allowed in scripts since Redis 5 because
-- scripts are replicated by their effects, not re-executed).
local capacity = tonumber(ARGV[1])
local rate = tonumber(ARGV[2])
local now = tonumber(ARGV[3])
local cost = tonumber(ARGV[4] or "1")

local state = redis.call("HMGET", KEYS[1], "tokens", "ts")
local tokens = tonumber(state[1]) or capacity       -- false (missing) -> full bucket
local ts = tonumber(state[2]) or now

-- refill for the time that passed, never above capacity
tokens = math.min(capacity, tokens + (now - ts) / 1000 * rate)

local allowed = 0
if tokens >= cost then
  tokens = tokens - cost
  allowed = 1
end
redis.call("HSET", KEYS[1], "tokens", tokens, "ts", now)
-- expire idle buckets once they would be full again anyway
redis.call("PEXPIRE", KEYS[1], math.ceil((capacity - tokens) / rate * 1000) + 1000)
-- floats would be truncated in the reply: return the token count as a string
return { allowed, string.format("%.2f", tokens) }
