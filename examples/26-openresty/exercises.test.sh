# host: openresty, redis
. ./openresty.sh
or_start || exit 1
U="http://127.0.0.1:$PORT"
echo "--- ex1: validation"
req -X POST -H 'Content-Type: application/json' --data '{"name":"Ann","age":41}' "$U/ex1/users"
req -X POST -H 'Content-Type: application/json' --data '{"name":"","age":4.5}' "$U/ex1/users"
req -X POST -H 'Content-Type: application/json' --data 'not json' "$U/ex1/users"
req -X POST -H 'Content-Type: text/plain' --data 'x' "$U/ex1/users"
req "$U/ex1/users"
echo "--- ex2: per-path hits"
for p in a b a c a b; do curl -s "$U/ex2/$p" > /dev/null; done
req "$U/ex2/top"
echo "--- ex3: cache-aside"
for i in 1 2; do curl -sS -D - "$U/ex3/square?n=12" | grep -i -E '^x-cache|\^2' | tr -d '\r'; done
echo "--- ex4: HMAC signatures"
sign() { python3 -c 'import hmac,hashlib,base64,sys; print(base64.b64encode(hmac.new(b"lesson26-secret", sys.argv[1].encode(), hashlib.sha1).digest()).decode())' "$1"; }
now=$(date +%s)
req -H "X-Timestamp: $now" -H "X-Signature: $(sign "GET
/ex4/signed
$now")" "$U/ex4/signed"
req -H "X-Timestamp: $now" -H "X-Signature: $(sign "POST
/ex4/signed
$now")" "$U/ex4/signed"
old=$((now - 3600))
req -H "X-Timestamp: $old" -H "X-Signature: $(sign "GET
/ex4/signed
$old")" "$U/ex4/signed"
or_stop
