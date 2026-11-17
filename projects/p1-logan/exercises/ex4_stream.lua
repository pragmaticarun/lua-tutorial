-- Exercise 4 (solution): parse a log that arrives in arbitrary chunks (a
-- socket, `tail -f`). Keep the unfinished last line until its newline arrives.
package.path = "../src/?.lua;../src/?/init.lua;" .. package.path
local parse = require("logan.parse")
local report = require("logan.report")

local function streamer(on_line)
  local pending = ""
  return function(chunk)                 -- call with nil at end of input
    if chunk == nil then
      if pending ~= "" then on_line(pending) end
      pending = ""
      return
    end
    pending = pending .. chunk
    local last = 1
    for line, rest in pending:gmatch("([^\n]*)\n()") do   -- () captures a position
      on_line(line)
      last = rest                        -- just after this newline
    end
    pending = pending:sub(last)          -- keep only the unfinished tail
  end
end

local f = assert(io.open("../data/app.log", "rb"))
local data = f:read("*a")                -- "*a" works on 5.1 too ("a" is 5.3+)
f:close()

local st, n = report.new(), 0
local feed = streamer(function(line) n = n + 1; report.add(st, parse.line(line), n) end)
local pos, size = 1, 1
while pos <= #data do                    -- chunks of 1, 2, ... 97 bytes, then again
  feed(data:sub(pos, pos + size - 1))
  pos, size = pos + size, size % 97 + 1
end
feed(nil)
print(report.text(st, 2):match("^[^\n]*"))   -- first line of the report
print("same as reading whole lines:", n == select(2, data:gsub("\n", "")))
