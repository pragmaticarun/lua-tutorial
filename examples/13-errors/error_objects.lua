-- error_objects.lua: errors can be any value; tables carry structure
local DecodeError = {}
DecodeError.__index = DecodeError
DecodeError.__tostring = function(e)
  return ("DecodeError[%s] at frame %d: %s"):format(e.code, e.frame, e.msg)
end
local function decode_error(code, frame, msg)
  return setmetatable({ code = code, frame = frame, msg = msg }, DecodeError)
end

local function decode(frame)
  if frame == 3 then error(decode_error("EAGAIN", frame, "need more data")) end
  if frame == 5 then error("unexpected bug in decoder") end
  return "ok"
end

for _, frame in ipairs({ 1, 3, 5 }) do
  local ok, e = pcall(decode, frame)
  if ok then
    print(frame, e)
  elseif getmetatable(e) == DecodeError then     -- recognise our own errors
    print(frame, "recoverable:", e.code, tostring(e))
  else
    print(frame, "fatal:", e)                    -- strings get a position prefix
  end
end
