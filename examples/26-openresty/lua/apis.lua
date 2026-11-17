-- host: openresty
-- A tour of the ngx.* API, one handler per location (see conf/apis.conf).
-- Modules are loaded once per worker and cached: keep request state in
-- locals or ngx.ctx, never in module-level variables.
local cjson = require("cjson.safe")   -- .safe: returns nil, err instead of raising
local M = {}

local function sorted_lines(t, prefix)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do
    local v = t[k]
    if type(v) == "table" then v = table.concat(v, ",") end
    ngx.say(prefix, k, " = ", tostring(v))
  end
end

function M.echo()
  ngx.say("method: ", ngx.req.get_method())
  ngx.say("uri: ", ngx.var.uri, "  args: ", ngx.var.args or "")
  sorted_lines(ngx.req.get_uri_args(), "arg ")           -- repeated args -> table
  local h = ngx.req.get_headers()                         -- keys lower-cased
  ngx.say("header x-demo = ", h["x-demo"] or "-", "  (h.X_Demo also works: ", h.X_Demo or "-", ")")
  ngx.req.read_body()                                     -- bodies are not read by default
  local body = ngx.req.get_body_data()
  if body then
    local doc, err = cjson.decode(body)
    if doc then sorted_lines(doc, "json ") else ngx.say("body is not JSON: ", err) end
  end
end

function M.counter()
  local dict = ngx.shared.stats
  -- incr with an init value is atomic across workers
  local n = dict:incr("hits:" .. (ngx.var.arg_page or "home"), 1, 0)
  ngx.say("hits: ", n)
  if ngx.var.arg_page == "flash" then
    dict:set("flash", "visible for 1s", 1)             -- ttl in seconds
  end
  ngx.say("flash: ", dict:get("flash") or "(none)")
end

function M.regex()
  local s = ngx.var.arg_s or ""
  -- "jo": PCRE JIT + cache the compiled pattern; always use it in hot paths
  local m = ngx.re.match(s, [[(?<user>\w+)@(?<host>[\w.]+)]], "jo")
  if m then ngx.say("user=", m.user, " host=", m.host, " whole=", m[0]) end
  local masked, n = ngx.re.gsub(s, [[\d]], "#", "jo")
  ngx.say("masked: ", masked, " (", n, " digits)")
  for word in ngx.re.gmatch(s, [[[a-z]+]], "jo") do ngx.print(word[0], ";") end
  ngx.say()
end

function M.status()
  -- set status and headers BEFORE the first ngx.say: output sends headers
  ngx.status = ngx.HTTP_CREATED
  ngx.header["Content-Type"] = "application/json"
  ngx.header["X-Powered-By"] = { "Lua", "OpenResty" }   -- multi-value header
  ngx.say(cjson.encode({ created = true }))
  return ngx.exit(ngx.HTTP_OK)                            -- 200 here = "done, keep status"
end

function M.subrequests()
  -- subrequests run inside nginx (no network); capture_multi runs them in parallel
  local a, b = ngx.location.capture_multi({
    { "/internal/a", { args = { x = 1 } } },
    { "/internal/b", { args = "y=2" } },
  })
  ngx.print(a.status, " ", a.body, b.status, " ", b.body)
end

return M
