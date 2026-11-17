# Helpers sourced by the *.test.sh drivers: start OpenResty with this
# lesson's config in a throw-away prefix, and stop it again.
#   OR_PORT     main server port (gateway = +1, backends = +2)
#   REDIS_PORT  Redis used by the cosocket examples and the gateway
PORT=${OR_PORT:-8089}
GW_PORT=$((PORT + 1)); BACKEND_PORT=$((PORT + 2))
REDIS_PORT=${REDIS_PORT:-6379}

or_start() {
  OR_PREFIX=$(mktemp -d)
  mkdir -p "$OR_PREFIX/conf" "$OR_PREFIX/logs"
  for f in conf/*.conf; do
    sed -e "s|__PORT__|$PORT|g; s|__GW_PORT__|$GW_PORT|g; s|__BACKEND_PORT__|$BACKEND_PORT|g" \
        -e "s|__REDIS_PORT__|$REDIS_PORT|g; s|__DIR__|$PWD|g" "$f" > "$OR_PREFIX/$f"
  done
  openresty -p "$OR_PREFIX" -c conf/nginx.conf || { cat "$OR_PREFIX/logs/error.log"; return 1; }
  for _ in $(seq 50); do curl -s -o /dev/null "http://127.0.0.1:$PORT/" && return 0; sleep 0.1; done
  echo "openresty did not start"; cat "$OR_PREFIX/logs/error.log"; return 1
}

or_stop() {
  openresty -p "$OR_PREFIX" -s quit
  for _ in $(seq 50); do [ -f "$OR_PREFIX/logs/nginx.pid" ] || break; sleep 0.1; done
  # surface Lua errors: any [error] line in the log is a test failure
  if grep -q '\[error\]' "$OR_PREFIX/logs/error.log"; then
    echo "errors in error.log:"; grep '\[error\]' "$OR_PREFIX/logs/error.log" | sed 's/^[^[]*//'
  fi
  rm -rf "$OR_PREFIX"
}

# curl wrapper: -s silent, -S show errors; prints status code then body
req() { curl -sS -w '\n[%{http_code}]\n' "$@"; }
