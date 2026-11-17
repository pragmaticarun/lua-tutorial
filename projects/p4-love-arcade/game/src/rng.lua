-- rng.lua: a seeded Park-Miller generator. math.random differs between Lua
-- versions (5.4 uses xoshiro, LuaJIT its own), so a game that must replay
-- identically everywhere brings its own. All arithmetic stays below 2^53.
local RNG = {}
RNG.__index = RNG

function RNG.new(seed) return setmetatable({ s = seed % 2147483646 + 1 }, RNG) end

function RNG:next()                 -- 1 .. 2^31-2
  self.s = (self.s * 16807) % 2147483647
  return self.s
end

function RNG:float() return (self:next() - 1) / 2147483646 end       -- [0, 1)
function RNG:range(lo, hi) return lo + (self:next() - 1) % (hi - lo + 1) end

return RNG
