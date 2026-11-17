-- host: openresty
-- Exercise 3: cache-aside in Redis over a cosocket. The "expensive"
-- computation is a square with a 200 ms sleep; X-Cache says HIT or MISS.
local redis = require("resty.redis")
local config = require("gateway").config
local M = {}

function M.handle()
  local n = tonumber(ngx.var.arg_n)
  if not n then return ngx.exit(400) end
  local red = redis:new()
  red:set_timeouts(500, 500, 500)
  local ok, err = red:connect("127.0.0.1", config.redis_port)
  local key = "square:" .. n
  local cached = ok and red:get(key)
  if cached and cached ~= ngx.null then
    ngx.header["X-Cache"] = "HIT"
  else
    if not ok then ngx.log(ngx.WARN, "redis: ", err) end
    ngx.sleep(0.2)                                 -- pretend this is slow
    cached = tostring(n * n)
    if ok then red:setex(key, 30, cached) end
    ngx.header["X-Cache"] = "MISS"
  end
  if ok then red:set_keepalive(10000, 50) end
  ngx.say(n, "^2 = ", cached)
end

return M
