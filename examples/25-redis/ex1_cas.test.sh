# host: redis
R="redis-cli -p ${REDIS_PORT:-6379}"
cas() { printf 'cas %-6s -> %-6s : ' "${1:-<none>}" "$2"; $R --eval ex1_cas.lua config:{v} , "$1" "$2"; }
cas "" v1        # create
cas "" v2        # already exists: refused
cas v1 v2        # expected matches
cas v1 v3        # stale expectation: refused
echo "final: $($R GET config:{v})"
