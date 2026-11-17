# host: redis
R="redis-cli -p ${REDIS_PORT:-6379} --no-raw"

echo "--- FUNCTION LOAD reads the library from stdin with -x"
$R -x FUNCTION LOAD < ratelimit_lib.lua
echo "--- loading it again needs REPLACE"
$R -x FUNCTION LOAD < ratelimit_lib.lua
$R -x FUNCTION LOAD REPLACE < ratelimit_lib.lua

echo "--- FCALL name numkeys key... arg..."
for i in 1 2 3 4; do $R FCALL rl_hit 1 'rl:{ann}' 3 60; done
$R FCALL_RO rl_peek 1 'rl:{ann}'
echo "--- FCALL_RO refuses functions without the no-writes flag"
$R FCALL_RO rl_hit 1 'rl:{ann}' 3 60
$R FCALL rl_reset 1 'rl:{ann}'
$R FCALL rl_peek 1 'rl:{ann}'

echo "--- FUNCTION LIST describes what is loaded (sorted: the server's order is a hash order)"
redis-cli -p "${REDIS_PORT:-6379}" FUNCTION LIST LIBRARYNAME ratelimit |
  awk 'prev == "name" { print "function " $0 } prev == "engine" { print "engine " $0 } { prev = $0 }' | sort
echo "--- FUNCTION DUMP / RESTORE move libraries between servers"
# --raw prints the binary payload plus a newline; head -c -1 drops that newline
$R --raw FUNCTION DUMP > lib.dump
$R FUNCTION FLUSH
$R FCALL rl_peek 1 'rl:{ann}'
head -c -1 lib.dump | $R -x FUNCTION RESTORE
$R FCALL rl_peek 1 'rl:{ann}'
rm -f lib.dump
