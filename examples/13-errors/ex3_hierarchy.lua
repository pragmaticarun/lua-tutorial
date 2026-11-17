-- Exercise 3 solution: an error hierarchy with is_a checks
local function class(parent)
  local c = setmetatable({}, { __index = parent })
  c.__index, c.parent = c, parent
  c.__tostring = function(e) return e.name .. ": " .. e.msg end
  return c
end
local IOError = class()
IOError.name = "IOError"
local NetworkError = class(IOError)
NetworkError.name = "NetworkError"
local function raise(cls, msg) error(setmetatable({ msg = msg }, cls)) end
local function is_a(e, cls)
  local c = type(e) == "table" and getmetatable(e) or nil
  while c do if c == cls then return true end c = c.parent end
  return false
end

local cases = {
  function() raise(NetworkError, "connection reset") end,
  function() raise(IOError, "disk full") end,
  function() error("plain string") end,
}
for _, fn in ipairs(cases) do
  local ok, e = pcall(fn)
  if is_a(e, NetworkError) then print("retry later ->", tostring(e))
  elseif is_a(e, IOError) then print("report to user ->", tostring(e))
  else print("bug ->", e) end
end
