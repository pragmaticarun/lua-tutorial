# host: openresty
. ./openresty.sh
or_start || exit 1
U="http://127.0.0.1:$PORT"
echo "--- /echo"
req "$U/echo?tag=a&tag=b&q=lua" -H 'X-Demo: 42' --data '{"name":"ann","n":3}'
echo "--- /counter (shared dict)"
req "$U/counter?page=home"; req "$U/counter?page=home"; req "$U/counter?page=flash"
sleep 1.2
req "$U/counter?page=home"
echo "--- /re (ngx.re)"
req "$U/re?s=mail+ann@example.org+at+10:45"
echo "--- /status"
curl -sS -D - "$U/status" | grep -i -E '^(HTTP|x-powered-by|content-type)|created' | tr -d '\r'
echo "--- /sub (subrequests)"
req "$U/sub"
echo "--- internal locations are hidden from clients"
req "$U/internal/a" -o /dev/null
or_stop
