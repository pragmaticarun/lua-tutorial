-- host: openresty
-- A deliberately tiny HTTP/1.0 GET over a cosocket (use lua-resty-http in
-- real code). Every call that would block -- connect, send, receive --
-- instead yields this request's coroutine back to nginx's event loop.
return function(host, port, path, timeout_ms)
  local sock = ngx.socket.tcp()
  sock:settimeout(timeout_ms or 1000)                 -- connect/send/read timeout
  local ok, err = sock:connect(host, port)
  if not ok then return nil, "connect: " .. err end
  sock:send("GET " .. path .. " HTTP/1.0\r\nHost: " .. host .. "\r\n\r\n")
  local status_line = sock:receive("*l")              -- one line
  local status = tonumber(status_line and status_line:match("^HTTP/%d%.%d (%d+)"))
  repeat local line = sock:receive("*l") until line == "" or line == nil   -- skip headers
  local body = sock:receive("*a")                     -- until the server closes
  sock:close()
  return status, body
end
