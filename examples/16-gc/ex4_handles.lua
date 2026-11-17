-- targets: 5.5, 5.4
-- Exercise 4 solution: deterministic close with __close, GC as a safety net
local open_handles = 0
local Handle = {}
Handle.__index = Handle
local function release(h, how)
  if not h.closed then
    h.closed = true
    open_handles = open_handles - 1
    print("released", h.name, "via", how)
  end
end
Handle.__close = function(h) release(h, "__close") end
Handle.__gc = function(h) release(h, "__gc") end

local function open(name)
  open_handles = open_handles + 1
  return setmetatable({ name = name }, Handle)
end

do
  local h <close> = open("camera")
  print("using", h.name, "open:", open_handles)
end
local forgotten = open("mic")            -- the caller forgot to close it
forgotten = nil
collectgarbage()
print("open:", open_handles)
