-- Step 1: one pattern, one line. string.match returns every capture, or
-- nil when the line does not fit, so "did it parse?" is a nil check.
local line = '198.51.100.23 - - [17/Nov/2026:10:00:08 +0000] "POST /login HTTP/1.1" 401 9614 "-" "curl/8.11"'

local ip, time, method, path, status, bytes =
  line:match('^(%S+) %S+ %S+ %[([^%]]+)%] "(%u+) (%S+)[^"]*" (%d%d%d) (%S+)')

print("ip     ", ip)
print("time   ", time)
print("request", method, path)
print("status ", status, type(status))          -- captures are strings...
print("as num ", tonumber(status) + 0 == 401)   -- ...convert explicitly
print("bytes  ", bytes)

-- the same pattern on something else: no error, just nil
print("garbage", ("this line is garbage"):match('^(%S+) %S+ %S+ %['))
