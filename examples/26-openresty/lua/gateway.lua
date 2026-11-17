-- host: openresty
-- A small API gateway: routing, API-key auth, Redis-backed rate limiting
-- (the Lesson 25 script, run over a cosocket), request ids, metrics.
local cjson = require("cjson.safe")
local redis = require("resty.redis")
local to_hex = require("resty.string").to_hex
local http_get = require("http_get")

local M = { config = {} }

-- Routes are matched in order; `backend` replaces the matched prefix.
local routes = {
  { name = "users",  prefix = "/api/users/", backend = "/users/", methods = { GET = true }, limit = 5 },
  { name = "orders", prefix = "/api/orders", backend = "/orders", methods = { GET = true }, limit = 100 },
  { name = "public", prefix = "/api/public/users/", backend = "/users/", methods = { GET = true },
    limit = 2, public = true },
  { name = "dashboard", exact = "/api/dashboard", methods = { GET = true }, limit = 100 },
}

-- init_by_lua: runs once, before the workers fork (their memory is shared
-- copy-on-write). Blocking file I/O is fine here, and only here.
function M.init(opts)
  M.config = opts
  local f = assert(io.open(opts.dir .. "/../25-redis/ratelimit_fixed.lua"))
  M.config.script = f:read("*a")
  f:close()
  M.config.sha = to_hex(ngx.sha1_bin(M.config.script))
  local keys = ngx.shared.apikeys
  keys:set("key-ann", "ann")
  keys:set("key-bo", "bo")
end

local function reject(status, msg, extra_headers)
  ngx.status = status
  ngx.header["Content-Type"] = "application/json"
  for k, v in pairs(extra_headers or {}) do ngx.header[k] = v end
  ngx.say(cjson.encode({ error = msg, request_id = ngx.var.request_id ~= "" }))
  return ngx.exit(status)
end

local function match_route(uri)
  for _, r in ipairs(routes) do
    if (r.exact and uri == r.exact) or (r.prefix and uri:sub(1, #r.prefix) == r.prefix) then
      return r
    end
  end
end

-- Run the Lesson 25 fixed-window script: EVALSHA first, EVAL on NOSCRIPT.
local function rate_limit(key, limit)
  local red = redis:new()
  red:set_timeouts(200, 200, 200)
  local ok, err = red:connect("127.0.0.1", M.config.redis_port)
  if not ok then return nil, err end
  local res
  res, err = red:evalsha(M.config.sha, 1, key, limit, 60)
  if not res and err and err:find("NOSCRIPT", 1, true) then
    res, err = red:eval(M.config.script, 1, key, limit, 60)
  end
  if not res then return nil, err end
  red:set_keepalive(10000, 100)
  return res[1] == 1, limit - res[2]
end

function M.access()
  local route = match_route(ngx.var.uri)
  if not route then return reject(404, "no route") end
  ngx.ctx.route = route.name
  if not route.methods[ngx.req.get_method()] then
    return reject(405, "method not allowed", { Allow = "GET" })
  end

  local consumer = "anonymous"
  if not route.public then
    local key = ngx.req.get_headers()["x-api-key"]
    consumer = key and ngx.shared.apikeys:get(key)
    if not consumer then return reject(401, "missing or unknown API key") end
  end

  local id = route.public and ngx.var.remote_addr or consumer
  local allowed, remaining = rate_limit("rl:{" .. id .. "}:" .. route.name, route.limit)
  if allowed == nil then
    -- Redis down: fail open, but count it
    ngx.log(ngx.WARN, "rate limiter unavailable: ", remaining)
    ngx.shared.metrics:incr("redis_errors", 1, 0)
  elseif not allowed then
    return reject(429, "rate limit exceeded", { ["Retry-After"] = "60" })
  end
  ngx.ctx.remaining = remaining

  ngx.req.set_header("X-Consumer", consumer)
  ngx.req.set_header("X-Request-Id", ngx.var.request_id)  -- nginx's $request_id
  ngx.req.clear_header("X-Api-Key")                        -- never leak keys upstream
  if route.prefix then
    ngx.var.backend_path = route.backend .. ngx.var.uri:sub(#route.prefix + 1)
  end
end

function M.header_filter()
  ngx.header["X-Gateway"] = "lesson26"
  if ngx.ctx.remaining then ngx.header["X-RateLimit-Remaining"] = ngx.ctx.remaining end
end

function M.log()
  ngx.shared.metrics:incr((ngx.ctx.route or "none") .. " " .. ngx.status, 1, 0)
end

-- Aggregate two backend calls concurrently with light threads.
function M.dashboard()
  local port = M.config.backend_port
  local user = ngx.var.arg_user or "1"
  local t1 = ngx.thread.spawn(http_get, "127.0.0.1", port, "/users/" .. user)
  local t2 = ngx.thread.spawn(http_get, "127.0.0.1", port, "/orders?user=" .. user)
  local _, s1, b1 = ngx.thread.wait(t1)
  local _, s2, b2 = ngx.thread.wait(t2)
  if s1 ~= 200 or s2 ~= 200 then return reject(502, "backend error") end
  ngx.header["Content-Type"] = "application/json"
  ngx.say(cjson.encode({ user = cjson.decode(b1), orders = cjson.decode(b2).orders }))
end

function M.metrics()
  local keys = ngx.shared.metrics:get_keys(0)
  table.sort(keys)
  for _, k in ipairs(keys) do ngx.say(k, " ", ngx.shared.metrics:get(k)) end
end

return M
