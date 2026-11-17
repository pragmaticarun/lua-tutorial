# host: redis
R="redis-cli -p ${REDIS_PORT:-6379} --no-raw"
for mode in call pcall raise global lua_error; do
  echo "--- $mode"
  # drop the trailing "script: <sha>, on @user_script:N." detail for brevity
  $R --eval errors.lua 'item:{1}' , "$mode" | sed 's/ script: [0-9a-f]*, on @user_script:[0-9]*\.$//'
done

echo "--- writes before an error are NOT rolled back"
$R EVAL 'redis.call("SET", KEYS[1], "written"); redis.call("INCR", KEYS[2])' 2 a:{1} b:{1} |
  sed 's/ script: .*//'
$R SET b:{1} text >/dev/null
$R EVAL 'redis.call("SET", KEYS[1], "written"); redis.call("INCR", KEYS[2])' 2 a:{1} b:{1} |
  sed 's/ script: .*//'
$R GET a:{1}

echo "--- a long-running script blocks the server; SCRIPT KILL stops it"
$R CONFIG SET busy-reply-threshold 100 >/dev/null
$R EVAL 'local i = 0 while true do i = i + 1 end' 0 > busy.out 2>&1 &
sleep 0.5
$R PING
$R SCRIPT KILL
wait
sed 's/ script: .*//' busy.out
$R PING
rm -f busy.out
$R CONFIG SET busy-reply-threshold 5000 >/dev/null
