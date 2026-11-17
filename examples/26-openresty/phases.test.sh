# host: openresty
. ./openresty.sh
or_start || exit 1
echo "--- one request through every phase"
curl -sS -D - -o body.out "http://127.0.0.1:$PORT/phases?name=lua" | grep -i -E '^(HTTP|x-trail)' | tr -d '\r'
cat body.out
echo "--- the log phase ran after the response was sent"
req "http://127.0.0.1:$PORT/phases/last"
echo "--- access phase can end the request early"
req "http://127.0.0.1:$PORT/phases?name=mallory" -o /dev/null
echo "--- rewrite phase can redirect"
curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' "http://127.0.0.1:$PORT/phases?old=1"
rm -f body.out
or_stop
