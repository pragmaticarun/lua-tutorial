-- Exercise 1 solution: nil+message for bad input, never raising
local function parse_resolution(s)
  if type(s) ~= "string" then return nil, "expected a string, got " .. type(s) end
  local w, h = s:match("^(%d+)x(%d+)$")
  if not w then return nil, ("bad resolution %q (want WxH)"):format(s) end
  w, h = tonumber(w), tonumber(h)
  if w == 0 or h == 0 then return nil, "zero dimension in " .. s end
  return w, h
end
for _, input in ipairs({ "1920x1080", "1920*1080", "0x720" }) do
  print(parse_resolution(input))
end
print(parse_resolution(42))
