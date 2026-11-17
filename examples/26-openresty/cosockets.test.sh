# host: openresty, redis
. ./openresty.sh
or_start || exit 1
U="http://127.0.0.1:$PORT"
echo "--- resty.redis"
req "$U/redis"
req "$U/redis"
echo "--- raw cosocket speaking RESP"
req "$U/raw"
echo "--- two backend calls in parallel light threads"
req "$U/parallel"
echo "--- ngx.timer.at + ngx.sleep"
req "$U/timer"
or_stop
