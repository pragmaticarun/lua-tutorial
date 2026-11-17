-- module
-- Turn key events into named actions. LÖVE calls love.keypressed/keyreleased;
-- we forward them here, so the game logic never asks "is key X down?" and can
-- be driven by a script in tests.
local Input = {}
Input.__index = Input

function Input.new(bindings)
  -- bindings: action -> list of keys, e.g. { left = { "left", "a" } }
  local key_to_action = {}
  for action, keys in pairs(bindings) do
    for _, k in ipairs(keys) do key_to_action[k] = action end
  end
  return setmetatable({ map = key_to_action, down = {}, pressed = {} }, Input)
end

function Input:keypressed(key)
  local a = self.map[key]
  if a then
    if not self.down[a] then self.pressed[a] = true end
    self.down[a] = (self.down[a] or 0) + 1   -- two keys may map to one action
  end
end

function Input:keyreleased(key)
  local a = self.map[key]
  if a and self.down[a] then
    self.down[a] = self.down[a] > 1 and self.down[a] - 1 or nil
  end
end

function Input:isDown(action) return self.down[action] ~= nil end

-- "pressed this frame": true once, then cleared by endFrame()
function Input:wasPressed(action) return self.pressed[action] == true end
function Input:endFrame() self.pressed = {} end

-- -1, 0 or 1 along an axis, e.g. axis("left", "right")
function Input:axis(neg, pos)
  return (self:isDown(pos) and 1 or 0) - (self:isDown(neg) and 1 or 0)
end

return Input
