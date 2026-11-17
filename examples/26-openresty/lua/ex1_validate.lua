-- host: openresty
-- Exercise 1: a JSON endpoint with validation and proper status codes.
local cjson = require("cjson.safe")
local M = {}

local function respond(status, tbl)
  ngx.status = status
  ngx.header["Content-Type"] = "application/json"
  ngx.say(cjson.encode(tbl))   -- note: cjson escapes "/" as "\/" by default
  return ngx.exit(status)
end

function M.handle()
  if ngx.req.get_method() ~= "POST" then return respond(405, { error = "POST only" }) end
  local ctype = ngx.var.content_type or ""
  if not ctype:find("^application/json") then
    return respond(415, { error = "expected application/json" })
  end
  ngx.req.read_body()
  local doc = cjson.decode(ngx.req.get_body_data() or "")
  if type(doc) ~= "table" then return respond(400, { error = "invalid JSON" }) end
  local problems = {}
  if type(doc.name) ~= "string" or #doc.name == 0 then problems[#problems + 1] = "name: required string" end
  local age = doc.age   -- JSON numbers are Lua numbers (LuaJIT: always doubles)
  if type(age) ~= "number" or age % 1 ~= 0 or age < 0 or age > 150 then
    problems[#problems + 1] = "age: integer 0-150"
  end
  if #problems > 0 then return respond(400, { errors = problems }) end
  return respond(201, { greeting = "welcome, " .. doc.name })
end

return M
