-- module
-- The game state and its update step. Pure Lua: positions in pixels,
-- dt in seconds. "Collect the coins, avoid the bouncing hazards."
local collision = require("collision")

local World = {}
World.__index = World

World.W, World.H = 320, 240
local SPEED = 120            -- player pixels per second

-- Tiny deterministic RNG: math.random differs between Lua versions, and
-- the products here stay below 2^53, so LuaJIT's doubles give the same
-- results as Lua 5.4/5.5 integers (Park-Miller "minimal standard").
local function lcg(seed)
  local s = seed
  return function(n)
    s = (s * 16807) % 2147483647
    return s % n
  end
end

function World.new(seed)
  local self = setmetatable({}, World)
  self.rand = lcg(seed or 1)
  self.player = { x = 150, y = 110, w = 16, h = 16 }
  self.walls = { { x = 100, y = 60, w = 120, h = 8 } }
  self.coins, self.hazards = {}, {}
  for _ = 1, 5 do self:spawnCoin() end
  self.hazards[1] = { x = 40, y = 40, r = 6, vx = 70, vy = 50 }
  self.score, self.hits, self.time, self.over = 0, 0, 0, false
  return self
end

function World:spawnCoin()
  local c = { x = 10 + self.rand(self.W - 20), y = 10 + self.rand(self.H - 20), r = 5 }
  self.coins[#self.coins + 1] = c
end

function World:update(dt, input)
  if self.over then return end
  self.time = self.time + dt
  local p = self.player
  p.x = collision.clamp(p.x + input:axis("left", "right") * SPEED * dt, 0, self.W - p.w)
  p.y = collision.clamp(p.y + input:axis("up", "down") * SPEED * dt, 0, self.H - p.h)
  for _, wall in ipairs(self.walls) do                  -- solid walls push back
    local mx, my = collision.resolve(p, wall)
    if mx then p.x, p.y = p.x + mx, p.y + my end
  end
  for i = #self.coins, 1, -1 do                         -- iterate backwards to remove
    if collision.circle_rect(self.coins[i], p) then
      table.remove(self.coins, i)
      self.score = self.score + 1
      self:spawnCoin()
    end
  end
  for _, h in ipairs(self.hazards) do                   -- bounce off the edges
    h.x, h.y = h.x + h.vx * dt, h.y + h.vy * dt
    if h.x < h.r or h.x > self.W - h.r then h.vx = -h.vx end
    if h.y < h.r or h.y > self.H - h.r then h.vy = -h.vy end
    if collision.circle_rect(h, p) then
      self.hits = self.hits + 1
      h.x, h.y = 40, 40                                 -- respawn the hazard
    end
  end
  if self.hits >= 3 then self.over = true end
end

return World
