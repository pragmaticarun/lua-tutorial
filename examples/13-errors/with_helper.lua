-- with_helper.lua: portable "finally" for LuaJIT and 5.1 (no <close>)
local unpack = table.unpack or unpack
local function with(resource, fn)
  local results = { pcall(fn, resource) }
  resource:close()                              -- runs on success and on error
  if not results[1] then error(results[2], 0) end
  return unpack(results, 2)
end
local Res = {}
Res.__index = Res
function Res.open(name) print("open " .. name); return setmetatable({ name = name }, Res) end
function Res:close() print("close " .. self.name) end

print(with(Res.open("a.wav"), function(r) return "read " .. r.name end))
print(pcall(with, Res.open("b.wav"), function() error("corrupt header", 0) end))
