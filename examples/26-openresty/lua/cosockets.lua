-- host: openresty
-- Cosockets: non-blocking sockets that look blocking. Each request runs in a
-- Lua coroutine; I/O yields to nginx, so one worker serves many requests.
local redis = require("resty.redis")
local http_get = require("http_get")
local config = require("gateway").config
local M = {}

function M.redis()
  local red = redis:new()
  red:set_timeouts(1000, 1000, 1000)              -- connect, send, read (ms)
  assert(red:connect("127.0.0.1", config.redis_port))
  red:set("demo:greeting", "hello from a cosocket")
  ngx.say("GET: ", (red:get("demo:greeting")))     -- methods return res, err
  ngx.say("missing key is ngx.null: ", tostring(red:get("demo:missing") == ngx.null))
  -- pipelining: queue commands, send them in one round trip
  red:init_pipeline()
  red:incr("demo:n"); red:incr("demo:n"); red:get("demo:n")
  local results = red:commit_pipeline()
  ngx.say("pipeline: ", table.concat(results, ","))
  ngx.say("reused times before keepalive: ", red:get_reused_times())
  -- return the connection to the per-worker pool instead of closing it
  red:set_keepalive(10000, 50)                     -- idle ms, pool size
end

function M.raw_resp()
  -- the Redis protocol by hand, to see the cosocket API itself
  local sock = ngx.socket.tcp()
  sock:settimeout(1000)
  assert(sock:connect("127.0.0.1", config.redis_port))
  sock:send("*1\r\n$4\r\nPING\r\n")
  ngx.say("PING -> ", sock:receive("*l"))
  sock:send("*2\r\n$4\r\nECHO\r\n$5\r\nhello\r\n")
  ngx.say("ECHO header -> ", sock:receive("*l"), ", payload -> ", sock:receive(5))
  sock:receive(2)                                   -- trailing \r\n
  sock:setkeepalive()
end

function M.parallel()
  local base = "/slow?ms=300&name="
  local t0 = ngx.now()
  -- light threads: run concurrently inside this request
  local th1 = ngx.thread.spawn(http_get, "127.0.0.1", config.backend_port, base .. "users")
  local th2 = ngx.thread.spawn(http_get, "127.0.0.1", config.backend_port, base .. "orders")
  local _, s1, b1 = ngx.thread.wait(th1)
  local _, s2, b2 = ngx.thread.wait(th2)
  ngx.update_time()
  local elapsed = ngx.now() - t0
  ngx.print(s1, " ", b1, s2, " ", b2)
  ngx.say("two 300 ms calls took < 550 ms: ", tostring(elapsed < 0.55))
end

function M.timer()
  -- timers run detached from the request (no ngx.say there); results go
  -- through a shared dict. ngx.sleep yields, it does not block the worker.
  local ok = ngx.timer.at(0.1, function(premature, msg)
    if premature then return end                    -- worker is shutting down
    ngx.shared.stats:set("timer_msg", msg)
  end, "set by a timer")
  ngx.say("timer scheduled: ", tostring(ok ~= nil))
  ngx.say("right away: ", tostring(ngx.shared.stats:get("timer_msg")))
  ngx.sleep(0.3)
  ngx.say("after ngx.sleep(0.3): ", ngx.shared.stats:get("timer_msg"))
end

return M
