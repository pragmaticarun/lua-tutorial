-- targets: 5.5, 5.4
-- finalizers.lua: __gc on tables (Lua 5.2+)
local function Resource(name)
  return setmetatable({ name = name }, {
    __gc = function(self) print("finalize", self.name) end,
  })
end

local a, b, c = Resource("a"), Resource("b"), Resource("c")
a, b, c = nil, nil, nil
collectgarbage()        -- finalizers run in reverse order of marking: c, b, a
print("--")

-- Gotcha: __gc must be present when setmetatable is called
local mt = {}
local late = setmetatable({ name = "late" }, mt)
mt.__gc = function() print("never printed") end
late = nil
collectgarbage()
print("late finalizer ignored")

-- Resurrection: a finalizer may store the object somewhere again
local graveyard = {}
local zombie = setmetatable({ name = "zombie" }, {
  __gc = function(self) graveyard[#graveyard + 1] = self end,
})
zombie = nil
collectgarbage()
print("resurrected:", graveyard[1].name)   -- usable, but finalized only once

-- Objects still alive at exit are finalized when the state closes
local keep = Resource("at-exit")
print("end of chunk")
