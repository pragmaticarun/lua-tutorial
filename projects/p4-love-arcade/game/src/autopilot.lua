-- autopilot.lua: a scripted player, for the attract mode and for tests. It
-- produces the same input table a human produces through the keyboard.
local Auto = {}
Auto.__index = Auto

function Auto.new(rng) return setmetatable({ rng = rng, frame = 0, aim = 0, wait = 0 }, Auto) end

function Auto:input(game)
  self.frame = self.frame + 1
  local input = { pressed = {} }
  local state = game:state()
  local function press(key) input.pressed[#input.pressed + 1] = key end
  if self.wait > 0 then self.wait = self.wait - 1 return input end
  if state == "title" then
    press(game.played and "escape" or "return")     -- one game, then quit
    game.played = true
    self.wait = 30
  elseif state == "game_over" then
    for _, k in ipairs({ "l", "u", "a", "return" }) do press(k) end
    self.wait = 30
  elseif state == "play" then
    local play = game.sm:top()
    local ball, pad = play.ball, play.paddle
    if ball.stuck then
      press("space")
      self.aim = (self.rng:float() - 0.5) * 40       -- where on the paddle to aim
    elseif self.frame >= 300 and not self.paused_once then
      press("p")                                      -- show the pause screen once
      self.paused_once, self.wait = true, 20
      return input
    end
    if ball.vy < 0 and (self.last_vy or 0) > 0 then   -- just bounced off the paddle:
      self.aim = (self.rng:float() - 0.5) * 40         -- aim somewhere new next time
    end
    self.last_vy = ball.vy
    local target = ball.x + self.aim
    local centre = pad.x + pad.w / 2
    -- a human-ish player: only reacts when the ball comes down, with a dead zone
    if ball.vy > 0 or ball.stuck then
      input.left, input.right = target < centre - 4, target > centre + 4
    end
  elseif state == "pause" then
    press("p")
  end
  return input
end

return Auto
