# host: redis
R="redis-cli -p ${REDIS_PORT:-6379}"
$R --eval ex3_json.lua stats:{page} , views 1 | paste -sd' '
$R --eval ex3_json.lua stats:{page} , views 5 | paste -sd' '
$R --eval ex3_json.lua stats:{page} , likes 2 | paste -sd' '
# read the stored document back with a script that decodes it
$R EVAL 'local d = cjson.decode(redis.call("GET", KEYS[1]))
         return { d.name, d.counters.views, d.counters.likes, d.updates }' 1 stats:{page} | paste -sd' '
