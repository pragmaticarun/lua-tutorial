# host: redis
R="redis-cli -p ${REDIS_PORT:-6379}"
# limit 3 per 1000 ms
for t in 0 200 400 600 999 1001 1250 1500; do
  printf 't=%-5s -> ' "$t"; $R --eval ex2_sliding_log.lua log:{u1} , 3 1000 "$t" "req-$t" | paste -sd' '
done
