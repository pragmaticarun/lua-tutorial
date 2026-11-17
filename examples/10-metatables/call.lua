-- call.lua: __call makes a table callable (a functor with state)
local function counter()
  return setmetatable({ n = 0 }, {
    __call = function(self, step) self.n = self.n + (step or 1); return self.n end,
  })
end
local c = counter()
print(c(), c(), c(10), c.n)               -- callable AND has fields
print(type(c))                            -- still a table
