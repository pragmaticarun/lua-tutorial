-- host: openresty
-- Exercise 4: HMAC request signing. The client sends
--   X-Timestamp: <unix seconds>
--   X-Signature: base64(hmac_sha1(secret, METHOD .. "\n" .. URI .. "\n" .. timestamp))
-- and the gateway recomputes it. Old timestamps are rejected (replay window).
local M = {}
local SECRET = "lesson26-secret"
local WINDOW = 300

function M.access()
  local h = ngx.req.get_headers()
  local ts, sig = tonumber(h["x-timestamp"]), h["x-signature"]
  if not ts or not sig then return ngx.exit(ngx.HTTP_UNAUTHORIZED) end
  if math.abs(ngx.time() - ts) > WINDOW then
    ngx.status = 401; ngx.say("timestamp outside the replay window"); return ngx.exit(401)
  end
  local msg = ngx.req.get_method() .. "\n" .. ngx.var.uri .. "\n" .. h["x-timestamp"]
  local expected = ngx.encode_base64(ngx.hmac_sha1(SECRET, msg))
  if sig ~= expected then
    ngx.status = 401; ngx.say("bad signature"); return ngx.exit(401)
  end
end

return M
