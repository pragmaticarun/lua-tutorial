-- targets: 5.5, 5.4
-- close_co.lua: coroutine.close and to-be-closed variables (Lua 5.4+)
local co = coroutine.create(function()
  local res <close> = setmetatable({}, { __close = function() print("released") end })
  coroutine.yield("working")
  print("never reached")
end)
print(coroutine.resume(co))
print(coroutine.close(co), coroutine.status(co))   -- runs pending __close

-- the generic for also accepts a 4th value: a closing value (5.4+)
local function lines_of(text)
  local closer = setmetatable({}, { __close = function() print("iterator closed") end })
  return text:gmatch("[^\n]+"), nil, nil, closer
end
for line in lines_of("a\nb\nc") do
  if line == "b" then break end                     -- break still closes
  print(line)
end
