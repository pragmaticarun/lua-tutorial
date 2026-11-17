-- game.lua: ties the states together. Owns the state machine, the RNG, the
-- high scores and an event log (what happened, for sounds, tests and replays).
local SM = require("src.statemachine")
local RNG = require("src.rng")
local Play = require("src.play")
local S = require("src.states")
local H = require("src.highscores")
local levels = require("src.levels")

local Game = {}
Game.__index = Game

--- opts.seed: RNG seed; opts.storage: { read = fn() -> text, write = fn(text) };
--- opts.on_event: called as on_event(game, name, value) for each event
function Game.new(opts)
  local self = setmetatable({ sm = SM.new(), rng = RNG.new(opts.seed or 1), time = 0,
                              storage = opts.storage, on_event = opts.on_event }, Game)
  self.scores = H.parse(self.storage and self.storage.read() or "")
  self.sm:push(S.title(self))
  return self
end

function Game:state() return self.sm:top().name end

function Game:event(name, value)
  if self.on_event then self.on_event(self, name, value) end
end

function Game:new_game() self:start_level(1, 0, 3) end

function Game:start_level(n, score, lives)
  local play = Play.new(self, n, score, lives)
  play.name = "play"
  self.sm:switch(play)
  self:event("level", n)
end

function Game:level_cleared(play)
  if play.level == #levels then
    self:event("won", play.score)
    self:game_over(play.score)
  else
    self.sm:switch(S.level_clear(self, play.level + 1, play.score, play.lives))
  end
end

function Game:game_over(score)
  self.sm:switch(S.game_over(self, score))
  self:event("game_over", score)
end

function Game:pause() self.sm:push(S.pause(self)) self:event("pause") end
function Game:to_title() self.sm:switch(S.title(self)) self:event("title") end

function Game:save_scores()
  if self.storage then self.storage.write(H.serialize(self.scores)) end
end

--- input = { left = bool, right = bool, pressed = { "space", ... } }
function Game:update(dt, input)
  self.time = self.time + dt
  for _, key in ipairs(input.pressed or {}) do self.sm:keypressed(key) end
  self.sm:update(dt, input)
end

function Game:draw(g) self.sm:draw(g) end

return Game
