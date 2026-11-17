# host: redis
R="redis-cli -p ${REDIS_PORT:-6379} --no-raw"

echo "--- redis-cli --eval: keys before the comma, args after"
$R --eval hello.lua greeting , hello world

echo "--- EVAL with the script text and numkeys"
$R EVAL "$(cat hello.lua)" 1 greeting hi there

echo "--- SCRIPT LOAD caches it; the id is the SHA1 of the script text"
SHA=$($R SCRIPT LOAD "$(cat hello.lua)" | tr -d '"')
echo "sha matches sha1sum: $([ "$SHA" = "$(printf '%s' "$(cat hello.lua)" | sha1sum | cut -c1-40)" ] && echo yes)"
$R EVALSHA "$SHA" 1 greeting hey you
$R SCRIPT EXISTS "$SHA" 0000000000000000000000000000000000000000

echo "--- after SCRIPT FLUSH the client must fall back to EVAL"
$R SCRIPT FLUSH
$R EVALSHA "$SHA" 1 greeting hey you

echo "--- Redis's Lua is 5.1, with a few libraries preloaded"
$R EVAL 'return {_VERSION, type(cjson), type(cmsgpack), type(bit), type(struct), type(os.clock), type(os.time)}' 0
