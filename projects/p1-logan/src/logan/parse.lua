-- logan.parse: turn one log line into a record table.
--
-- Two formats:
--   combined  the nginx/Apache "combined" access log
--             1.2.3.4 - - [17/Nov/2026:10:00:01 +0000] "GET /a HTTP/1.1" 200 512 "-" "curl/8"
--   app       an application log
--             2026-11-17T10:00:01Z ERROR [db] connection refused (took 120ms)
local M = {}

local MONTHS = { Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
                 Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12 }

-- one pattern per format; %[ and %] are literal brackets, [^"]* is "anything
-- up to the next quote"
local COMBINED = '^(%S+) %S+ %S+ %[([^%]]+)%] "(%u+) (%S+)[^"]*" (%d%d%d) (%S+) "([^"]*)" "([^"]*)"'
local CLF_TIME = "^(%d+)/(%a+)/(%d+):(%d+):(%d+):(%d+)"
local APP      = "^(%d%d%d%d%-%d%d%-%d%d)T(%d%d:%d%d):%d%d%S* (%u+) %[([^%]]+)%] (.*)$"

function M.combined(line)
  local ip, time, method, path, status, bytes, referer, agent = line:match(COMBINED)
  if not ip then return nil, "not a combined log line" end
  local d, mon, y, h, mi = time:match(CLF_TIME)
  if not d or not MONTHS[mon] then return nil, "bad timestamp '" .. time .. "'" end
  return {
    kind = "access", ip = ip, method = method,
    path = path:match("^[^?]*"),                 -- drop the query string
    status = tonumber(status),
    bytes = tonumber(bytes) or 0,                -- "-" means no body
    referer = referer, agent = agent,
    minute = ("%s-%02d-%02d %s:%s"):format(y, MONTHS[mon], tonumber(d), h, mi),
  }
end

function M.app(line)
  local date, hm, level, component, message = line:match(APP)
  if not date then return nil, "not an app log line" end
  return {
    kind = "app", level = level, component = component, message = message,
    ms = tonumber(message:match("%(took (%d+)ms%)")),   -- nil when absent
    minute = date .. " " .. hm,
  }
end

-- "auto" tries each format in turn
function M.line(line, format)
  if format == "combined" or format == "app" then return M[format](line) end
  local rec = M.combined(line)
  if rec then return rec end
  rec = M.app(line)
  if rec then return rec end
  return nil, "unrecognised line"
end

return M
