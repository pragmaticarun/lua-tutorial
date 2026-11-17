-- host: redis
-- Exercise 3: atomically update a JSON document stored in a string key,
-- with the cjson library Redis preloads. ARGV[1] = field, ARGV[2] = increment.
local raw = redis.call("GET", KEYS[1])
local doc = raw and cjson.decode(raw) or { name = KEYS[1], counters = {} }
local field, by = ARGV[1], tonumber(ARGV[2])
doc.counters[field] = (doc.counters[field] or 0) + by
doc.updates = (doc.updates or 0) + 1
redis.call("SET", KEYS[1], cjson.encode(doc))
-- return values, not the encoded text: cjson's key order is not guaranteed
return { field, doc.counters[field], doc.updates }
