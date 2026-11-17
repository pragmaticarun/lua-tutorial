-- host: openresty
-- Exercise 2: count hits per path in a shared dict; /ex2/top lists the top 3.
local M = {}

function M.handle()
  local dict = ngx.shared.stats
  if ngx.var.uri == "/ex2/top" then
    local rows = {}
    for _, k in ipairs(dict:get_keys(0)) do
      local path = k:match("^path:(.*)")
      if path then rows[#rows + 1] = { path = path, n = dict:get(k) } end
    end
    table.sort(rows, function(a, b) return a.n > b.n or (a.n == b.n and a.path < b.path) end)
    for i = 1, math.min(3, #rows) do ngx.say(rows[i].n, " ", rows[i].path) end
    return
  end
  local n = dict:incr("path:" .. ngx.var.uri, 1, 0)
  ngx.say(ngx.var.uri, " seen ", n, " time(s)")
end

return M
