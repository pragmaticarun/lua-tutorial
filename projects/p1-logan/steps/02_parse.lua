-- Step 2: the parser module. Run from steps/, so point package.path at src/.
package.path = "../src/?.lua;../src/?/init.lua;" .. package.path
local parse = require("logan.parse")

local function show(rec, err)
  if not rec then print("  error: " .. err) return end
  local keys = {}
  for k in pairs(rec) do keys[#keys + 1] = k end
  table.sort(keys)                               -- pairs() order is not defined
  for _, k in ipairs(keys) do print(("  %-9s %s"):format(k, tostring(rec[k]))) end
end

print("combined:")
show(parse.line('203.0.113.7 - - [17/Nov/2026:10:04:59 +0000] "GET /api/streams/42?token=abc HTTP/1.1" 304 - "-" "mpv 0.42.0"'))
print("app:")
show(parse.line("2026-11-17T10:00:27Z WARN [db] slow query (took 812ms)"))
print("forced format:")
show(parse.line("2026-11-17T10:00:27Z WARN [db] slow query", "combined"))
