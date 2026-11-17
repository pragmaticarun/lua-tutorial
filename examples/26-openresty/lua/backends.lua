-- host: openresty
-- Fake upstream services for the gateway: /users/<id>, /orders, /slow.
local cjson = require("cjson")
local M = {}

local users = { ["1"] = { id = 1, name = "Ann" }, ["2"] = { id = 2, name = "Bo" } }

function M.handle()
  local uri = ngx.var.uri
  ngx.header["Content-Type"] = "application/json"
  local id = uri:match("^/users/(%d+)$")
  if id then
    if not users[id] then ngx.status = 404; ngx.say('{"error":"no such user"}'); return end
    local u = users[id]
    -- reflect what the gateway forwarded, so tests can see it
    ngx.say(cjson.encode({ id = u.id, name = u.name, consumer = ngx.var.http_x_consumer,
                           request_id = ngx.var.http_x_request_id ~= nil }))
  elseif uri == "/orders" then
    ngx.say(cjson.encode({ user = tonumber(ngx.var.arg_user), orders = { 101, 102 } }))
  elseif uri == "/slow" then
    ngx.sleep(tonumber(ngx.var.arg_ms or 100) / 1000)
    ngx.header["Content-Type"] = "text/plain"
    ngx.say("slow ", ngx.var.arg_name)
  else
    ngx.status = 404; ngx.say('{"error":"not found"}')
  end
end

return M
