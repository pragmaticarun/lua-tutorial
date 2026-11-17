# host: redis
R="redis-cli -p ${REDIS_PORT:-6379} --no-raw"
for c in integer float float_s true false nil array holes map status err from_redis; do
  echo "--- $c"
  $R --eval conversions.lua , "$c"
done
