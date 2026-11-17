-- Exercise 3 (solution): a CSV renderer for the top lists (RFC 4180 quoting:
-- quote a field containing a comma, quote or newline; double inner quotes).
package.path = "../src/?.lua;../src/?/init.lua;" .. package.path
local report = require("logan.report")

local function field(v)
  v = tostring(v)
  if v:find('[,"\r\n]') then return '"' .. v:gsub('"', '""') .. '"' end
  return v
end

local function csv(st, n)
  local rows = { "list,key,count" }
  for _, list in ipairs({ "paths", "ips", "components" }) do
    for _, e in ipairs(report.top(st[list], n)) do
      rows[#rows + 1] = table.concat({ field(list), field(e.key), field(e.count) }, ",")
    end
  end
  return table.concat(rows, "\n")
end

local st = report.new()
report.add(st, { kind = "access", ip = "10.0.0.1", path = "/a,b", status = 200, bytes = 1, minute = "m" }, "x:1")
report.add(st, { kind = "access", ip = "10.0.0.1", path = '/say "hi"', status = 200, bytes = 1, minute = "m" }, "x:2")
report.add(st, { kind = "app", level = "INFO", component = "db", minute = "m" }, "x:3")
print(csv(st, 5))
