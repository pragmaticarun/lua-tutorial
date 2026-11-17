-- states.lua: the screens around the gameplay. Each is a small table with
-- the state-machine callbacks; `game` gives them access to the shared parts.
local H = require("src.highscores")

local S = {}

function S.title(game)
  local t = { name = "title" }
  function t:keypressed(key)
    if key == "return" or key == "space" then game:new_game()
    elseif key == "escape" then game:event("quit") end
  end
  function t:draw(g)
    g.setColor(1, 1, 1)
    g.printf("BRICK RUSH", 0, 60, 320, "center")
    g.printf("press Enter", 0, 90, 320, "center")
    for i, e in ipairs(game.scores) do
      g.printf(("%d. %-3s %6d"):format(i, e.name, e.score), 0, 120 + i * 14, 320, "center")
    end
  end
  return t
end

function S.pause(game)
  local t = { name = "pause" }
  function t:keypressed(key)
    if key == "p" or key == "escape" then game.sm:pop() end
  end
  function t:draw(g)
    g.setColor(0, 0, 0, 0.6)
    g.rectangle("fill", 0, 0, 320, 240)
    g.setColor(1, 1, 1)
    g.printf("PAUSED", 0, 110, 320, "center")
  end
  return t
end

-- a short pause between levels; the finished level stays visible underneath
function S.level_clear(game, next_level, score, lives)
  local t = { name = "level_clear", timer = 1.5 }
  function t:update(dt)
    t.timer = t.timer - dt
    if t.timer <= 0 then game:start_level(next_level, score, lives) end
  end
  function t:draw(g)
    g.setColor(1, 1, 1)
    g.printf(("LEVEL %d"):format(next_level), 0, 110, 320, "center")
  end
  return t
end

-- game over: type up to three letters for the high-score table
function S.game_over(game, score)
  local t = { name = "game_over", initials = "" }
  local qualifies = H.qualifies(game.scores, score)
  function t:keypressed(key)
    if qualifies and #key == 1 and key:match("%a") and #t.initials < 3 then
      t.initials = t.initials .. key:upper()
    elseif qualifies and key == "backspace" then
      t.initials = t.initials:sub(1, -2)
    elseif key == "return" then
      if qualifies then
        local rank = H.insert(game.scores, score, t.initials ~= "" and t.initials or "AAA")
        game:save_scores()
        game:event("highscore", rank)
      end
      game:to_title()
    end
  end
  function t:draw(g)
    g.setColor(1, 0.4, 0.4)
    g.printf("GAME OVER", 0, 90, 320, "center")
    g.setColor(1, 1, 1)
    g.printf(("score %d"):format(score), 0, 110, 320, "center")
    if qualifies then g.printf("new high score! " .. t.initials .. "_", 0, 130, 320, "center") end
  end
  return t
end

return S
