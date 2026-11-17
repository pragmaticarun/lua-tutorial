-- host: redis
-- Exercise 1: compare-and-set. Set KEYS[1] to ARGV[2] only if its current
-- value is ARGV[1] ("" means "must not exist"). Returns 1 if set, else 0.
local current = redis.call("GET", KEYS[1])     -- false if missing
local expected = ARGV[1]
if (expected == "" and current == false) or current == expected then
  redis.call("SET", KEYS[1], ARGV[2])
  return 1
end
return 0
