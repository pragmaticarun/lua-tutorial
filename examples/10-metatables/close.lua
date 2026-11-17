-- targets: 5.5, 5.4
-- close.lua: __close runs when a <close> variable goes out of scope
local function resource(name)
  print("open  " .. name)
  return setmetatable({ name = name }, {
    __close = function(self, err)
      print("close " .. self.name .. (err and (" (error: " .. tostring(err) .. ")") or ""))
    end,
  })
end

do
  local a <close> = resource("decoder")
  local b <close> = resource("output")    -- closed first: reverse order
  print("working")
end

local ok, msg = pcall(function()
  local f <close> = resource("file")
  error("disk full", 0)                    -- __close still runs, and sees the error
end)
print(ok, msg)

local function early()
  local r <close> = resource("early")
  if true then return "returned" end       -- leaving by return closes too
end
print(early())
