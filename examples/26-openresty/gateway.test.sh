# host: openresty, redis
. ./openresty.sh
or_start || exit 1
G="http://127.0.0.1:$GW_PORT"
J() { python3 -c 'import json,sys; t=sys.stdin.read().split("\n[",1); print(json.dumps(json.loads(t[0]),sort_keys=True)); print("["+t[1].strip())'; }
echo "--- authenticated request, proxied to /users/1"
req -H 'X-API-Key: key-ann' "$G/api/users/1" | J
echo "--- headers added by the gateway"
curl -sS -D - -o /dev/null -H 'X-API-Key: key-ann' "$G/api/users/2" | grep -i -E '^x-(gateway|ratelimit)' | tr -d '\r'
echo "--- no key / wrong key / wrong method / unknown route"
req "$G/api/users/1" | J
req -H 'X-API-Key: nope' "$G/api/users/1" | J
req -X POST -H 'X-API-Key: key-ann' "$G/api/users/1" | J
req "$G/api/nothing" | J
echo "--- backend 404 passes through"
req -H 'X-API-Key: key-ann' "$G/api/users/9" | J
echo "--- rate limit: users route allows 5 per minute per consumer"
for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w '%{http_code} ' -H 'X-API-Key: key-bo' "$G/api/users/1"; done; echo
req -H 'X-API-Key: key-ann' "$G/api/users/1" -o /dev/null
echo "(ann is limited separately)"
echo "--- query strings are forwarded"
req -H 'X-API-Key: key-ann' "$G/api/orders?user=2" | J
echo "--- public route: no key, limit 2"
for i in 1 2 3; do curl -s -o /dev/null -w '%{http_code} ' "$G/api/public/users/2"; done; echo
echo "--- aggregation with light threads"
req -H 'X-API-Key: key-bo' "$G/api/dashboard?user=2" | J
echo "--- metrics collected in the log phase"
curl -sS "$G/metrics"
or_stop
