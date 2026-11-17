-- play.lua: the game itself. Pure logic: no love.* calls except in draw(),
-- so it runs (and is tested) on plain Lua as well as inside LÖVE.
local P = require("src.physics")
local levels = require("src.levels")

local Play = {}
Play.__index = Play

local W, H = 320, 240
local BRICK_W, BRICK_H, GAP, TOP = 28, 10, 2, 30
local PADDLE_SPEED, BALL_SPEED, MAX_SPEED = 220, 150, 260

function Play.new(game, level, score, lives)
  local self = setmetatable({ game = game, level = level, score = score or 0,
                              lives = lives or 3, combo = 0, bricks = {} }, Play)
  for row, line in ipairs(levels[level]) do
    for col = 1, #line do
      local c = line:sub(col, col)
      if c ~= "." then
        self.bricks[#self.bricks + 1] = {
          x = 10 + (col - 1) * (BRICK_W + GAP), y = TOP + (row - 1) * (BRICK_H + GAP),
          w = BRICK_W, h = BRICK_H, hits = c == "2" and 2 or 1, points = c == "2" and 25 or 10,
        }
      end
    end
  end
  self.paddle = { x = W / 2 - 24, y = 224, w = 48, h = 6 }
  self:serve()
  return self
end

function Play:serve()
  self.ball = { x = 0, y = 0, r = 3, vx = 0, vy = 0, speed = BALL_SPEED, stuck = true }
  self.combo = 0
end

function Play:keypressed(key)
  if key == "space" and self.ball.stuck then
    -- launch at a slightly random angle (the game's seeded RNG)
    local dx = (self.game.rng:float() - 0.5) * 0.8
    self.ball.vx, self.ball.vy = P.scale(dx, -1, self.ball.speed)
    self.ball.stuck = false
    self.game:event("launch")
  elseif key == "p" then
    self.game:pause()
  elseif key == "escape" then
    self.game:to_title()
  end
end

function Play:hit_brick(i, axis)
  local b, ball = self.bricks[i], self.ball
  if axis == "x" then ball.vx = -ball.vx else ball.vy = -ball.vy end
  b.hits = b.hits - 1
  if b.hits > 0 then return end
  table.remove(self.bricks, i)
  self.combo = self.combo + 1
  local points = b.points * math.min(self.combo, 4)    -- combo multiplier, up to x4
  self.score = self.score + points
  ball.speed = math.min(MAX_SPEED, ball.speed * 1.04)
  ball.vx, ball.vy = P.scale(ball.vx, ball.vy, ball.speed)
  self.game:event("brick", points)
  if #self.bricks == 0 then self.game:level_cleared(self) end
end

-- one small physics step; called several times per frame so a fast ball
-- cannot jump over a 10-pixel brick
function Play:step(dt)
  local ball, pad = self.ball, self.paddle
  ball.x, ball.y = ball.x + ball.vx * dt, ball.y + ball.vy * dt
  if ball.x < ball.r then ball.x, ball.vx = ball.r, math.abs(ball.vx) end
  if ball.x > W - ball.r then ball.x, ball.vx = W - ball.r, -math.abs(ball.vx) end
  if ball.y < ball.r then ball.y, ball.vy = ball.r, math.abs(ball.vy) end
  if ball.y > H + ball.r then                          -- fell past the paddle
    self.lives = self.lives - 1
    self.game:event("miss", self.lives)
    if self.lives == 0 then self.game:game_over(self.score) else self:serve() end
    return false
  end
  if ball.vy > 0 and P.circle_rect(ball.x, ball.y, ball.r, pad.x, pad.y, pad.w, pad.h) then
    -- where it hit the paddle (-1 .. 1) sets the new direction
    local offset = (ball.x - (pad.x + pad.w / 2)) / (pad.w / 2)
    ball.vx, ball.vy = P.scale(offset * 0.9, -1, ball.speed)
    ball.y = pad.y - ball.r
    self.combo = 0
    return true
  end
  for i = 1, #self.bricks do
    local b = self.bricks[i]
    local hit, axis = P.circle_rect(ball.x, ball.y, ball.r, b.x, b.y, b.w, b.h)
    if hit then
      self:hit_brick(i, axis)
      return #self.bricks > 0
    end
  end
  return true
end

function Play:update(dt, input)
  local pad = self.paddle
  local dir = (input.right and 1 or 0) - (input.left and 1 or 0)
  pad.x = math.max(0, math.min(W - pad.w, pad.x + dir * PADDLE_SPEED * dt))
  local ball = self.ball
  if ball.stuck then
    ball.x, ball.y = pad.x + pad.w / 2, pad.y - ball.r
    return
  end
  for _ = 1, 4 do
    if not self:step(dt / 4) then return end
  end
end

function Play:draw(g)
  for _, b in ipairs(self.bricks) do
    if b.hits == 2 then g.setColor(0.85, 0.35, 0.25) else g.setColor(0.95, 0.75, 0.25) end
    g.rectangle("fill", b.x, b.y, b.w, b.h)
  end
  g.setColor(0.3, 0.7, 0.95)
  g.rectangle("fill", self.paddle.x, self.paddle.y, self.paddle.w, self.paddle.h)
  g.setColor(1, 1, 1)
  g.circle("fill", self.ball.x, self.ball.y, self.ball.r)
  g.print(("L%d  score %d  lives %d"):format(self.level, self.score, self.lives), 4, 4)
end

return Play
