-- host: nvim
-- The event loop: vim.schedule, vim.defer_fn, vim.uv timers, vim.system, vim.wait.
-- In headless `nvim -l`, print() goes to Neovim's message area (stderr);
-- write test output to stdout explicitly.
local function say(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  io.write(table.concat(parts, " "), "\n")
end

local events = {}
local function log(e) events[#events + 1] = e end

-- vim.schedule queues a callback for the main loop: it runs after this chunk
-- yields to the loop (here: inside vim.wait below), never immediately.
vim.schedule(function() log("scheduled") end)
log("sync")

-- a timer in milliseconds
vim.defer_fn(function() log("deferred 20ms") end, 20)

-- libuv directly: a repeating timer. uv callbacks run in a "fast" context where
-- most vim.api calls are not allowed; vim.schedule_wrap hops back to the loop.
local uv = vim.uv
local ticks = 0
local timer = uv.new_timer()
timer:start(5, 5, vim.schedule_wrap(function()
  ticks = ticks + 1
  if ticks == 3 then
    timer:stop(); timer:close()
    log("timer ticked 3 times, api ok: " .. tostring(vim.api.nvim_get_current_buf() > 0))
  end
end))

-- run an external process asynchronously; on_exit runs in a fast context too
vim.system({ "sh", "-c", "echo from-child; exit 3" }, { text = true }, vim.schedule_wrap(function(res)
  log(("child exited %d: %s"):format(res.code, vim.trim(res.stdout)))
end))

-- vim.wait pumps the event loop until the predicate is true (or times out)
local ok = vim.wait(2000, function() return #events >= 5 end, 5)
say("waited ok:", ok)
table.sort(events, function(a, b)  -- the timer and the child race; sort the tail
  local order = { sync = 1, scheduled = 2 }
  return (order[a] or 3) < (order[b] or 3) or ((order[a] or 3) == (order[b] or 3) and a < b)
end)
for i, e in ipairs(events) do say(i, e) end

-- synchronous process call: :wait() blocks and returns the result table
local res = vim.system({ "printf", "%s-%s", "a", "b" }, { text = true }):wait()
say("sync child:", res.code, res.stdout)

-- what happens if a raw uv callback touches the API: an E5560 error
local fast_result
local t2 = uv.new_timer()
t2:start(0, 0, function()
  local okc, err = pcall(vim.api.nvim_set_current_line, "x")
  fast_result = ("in fast event: %s, ok=%s, %s"):format(
    tostring(vim.in_fast_event()), tostring(okc), tostring(err):match("E%d+"))
  t2:close()
end)
vim.wait(1000, function() return fast_result ~= nil end)
say(fast_result)
say("fast event now?", vim.in_fast_event())
