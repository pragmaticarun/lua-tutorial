-- two_styles.lua: Lua's two error conventions
-- 1. return nil plus a message (expected failures: missing files, bad input)
local f, err, code = io.open("does-not-exist.txt")
print(f, err, code)

local function parse_port(s)
  local n = tonumber(s)
  if not n or n % 1 ~= 0 or n < 1 or n > 65535 then
    return nil, "invalid port: " .. tostring(s)
  end
  return n
end
print(parse_port("8080"))
print(parse_port("http"))

-- 2. raise an error (bugs, violated preconditions); catch it with pcall
local ok, msg = pcall(function() local cfg = nil; return cfg.port end)
print(ok, msg)

-- assert converts style 1 into style 2
print(pcall(function() return assert(parse_port("99999")) end))
