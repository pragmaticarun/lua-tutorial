-- locals.lua: global and table lookups vs locals in a hot loop
local bench = require("bench")
local N = 1000000
local up_floor = math.floor                -- a chunk-level local, seen as an upvalue

bench.compare("locals vs globals", {
  { "global math.floor", function()
      local s = 0
      for i = 1, N do s = s + math.floor(i / 3) end
      return s
    end },
  { "local floor", function()
      local floor = math.floor              -- one lookup, hoisted out of the loop
      local s = 0
      for i = 1, N do s = s + floor(i / 3) end
      return s
    end },
  { "upvalue floor", function()
      local s = 0
      for i = 1, N do s = s + up_floor(i / 3) end  -- upvalue: one indirection
      return s
    end },
})
