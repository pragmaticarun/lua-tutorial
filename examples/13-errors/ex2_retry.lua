-- Exercise 2 solution: retry a failing operation a few times
local function retry(times, fn, ...)
  local last_err
  for attempt = 1, times do
    local ok, result = pcall(fn, ...)
    if ok then return result, attempt end
    last_err = result
    print(("attempt %d failed: %s"):format(attempt, tostring(result)))
  end
  error(("gave up after %d attempts: %s"):format(times, tostring(last_err)), 2)
end

local calls = 0
local function flaky_connect(host)
  calls = calls + 1
  if calls < 3 then error("timeout talking to " .. host, 0) end
  return "connected to " .. host
end
print(retry(5, flaky_connect, "cam-01"))
calls = -10
print(pcall(retry, 2, flaky_connect, "cam-02"))
