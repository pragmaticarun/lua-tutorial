-- host: redis
-- KEYS holds key names, ARGV holds everything else. Both are 1-based Lua
-- tables of strings. Declaring keys in KEYS lets Redis Cluster route the
-- script to the right shard and check they all live there.
redis.call("SET", KEYS[1], ARGV[1])
local greeting = redis.call("GET", KEYS[1])
return { "keys=" .. #KEYS, "argv=" .. #ARGV, greeting .. ", " .. ARGV[2] }
