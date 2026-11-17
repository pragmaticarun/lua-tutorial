-- Exercise 3: sprite-sheet animation logic (which frame/quad to draw).
-- In LÖVE: quads[i] = love.graphics.newQuad((i-1)*w, row*h, w, h, sheet)
-- and love.graphics.draw(sheet, quads[anim:frame()], x, y).
local Anim = {}
Anim.__index = Anim

function Anim.new(frames, fps, loop)
  return setmetatable({ frames = frames, dur = 1 / fps, loop = loop ~= false, t = 0, i = 1, done = false }, Anim)
end

function Anim:update(dt)
  if self.done then return end
  self.t = self.t + dt
  while self.t >= self.dur do
    self.t = self.t - self.dur
    if self.i < #self.frames then self.i = self.i + 1
    elseif self.loop then self.i = 1
    else self.done = true; break end
  end
end

function Anim:frame() return self.frames[self.i] end

local walk = Anim.new({ 1, 2, 3, 4 }, 8)               -- 8 fps, looping
local die = Anim.new({ 9, 10, 11 }, 10, false)         -- one-shot
local seq_w, seq_d = {}, {}
for _ = 1, 12 do
  walk:update(1 / 30); die:update(1 / 30)
  seq_w[#seq_w + 1] = walk:frame(); seq_d[#seq_d + 1] = die:frame()
end
print("walk:", table.concat(seq_w, " "))
print("die: ", table.concat(seq_d, " "), "done=" .. tostring(die.done))
