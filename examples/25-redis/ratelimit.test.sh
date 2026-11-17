# host: redis
R="redis-cli -p ${REDIS_PORT:-6379} --no-raw"
RAW="redis-cli -p ${REDIS_PORT:-6379}"

echo "--- fixed window: limit 5 per 60 s"
for i in 1 2 3 4 5 6 7; do
  printf 'request %d: ' "$i"
  $RAW --eval ratelimit_fixed.lua 'rl:{user42}' , 5 60 | head -2 | paste -sd' '
done
ttl=$($RAW PTTL 'rl:{user42}')
echo "window resets in (0, 60000] ms: $([ "$ttl" -gt 0 ] && [ "$ttl" -le 60000 ] && echo yes)"

echo "--- atomic under concurrency: 200 parallel clients, limit 50"
SHA=$($RAW SCRIPT LOAD "$(cat ratelimit_fixed.lua)")
for i in $(seq 200); do
  $RAW EVALSHA "$SHA" 1 'rl:{burst}' 50 60 | head -1 &
done > burst.out
wait
echo "allowed: $(grep -c '^1$' burst.out)  rejected: $(grep -c '^0$' burst.out)"
echo "counter: $($RAW GET 'rl:{burst}')"
rm -f burst.out

echo "--- token bucket: capacity 3, 1 token/s, times in ms"
for t in 0 100 200 300 400 1400 1500 5000 5000:3 5000:2; do
  now=${t%%:*}; cost=1; [[ $t == *:* ]] && cost=${t##*:}
  printf 't=%-5s cost=%s -> ' "$now" "$cost"
  $RAW --eval ratelimit_bucket.lua 'tb:{user42}' , 3 1 "$now" "$cost" | paste -sd' '
done
