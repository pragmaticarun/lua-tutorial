-- statemachine.lua: a stack of game states. switch() replaces the top,
-- push() pauses it under a new one (a pause menu), pop() returns to it.
-- A state is a table with optional enter/exit/update/keypressed/draw.
local SM = {}
SM.__index = SM

function SM.new() return setmetatable({ stack = {} }, SM) end

function SM:top() return self.stack[#self.stack] end

local function call(state, method, ...)
  if state and state[method] then return state[method](state, ...) end
end

function SM:switch(state, ...)
  call(self:top(), "exit")
  self.stack[math.max(1, #self.stack)] = state
  call(state, "enter", ...)
end

function SM:push(state, ...)
  self.stack[#self.stack + 1] = state
  call(state, "enter", ...)
end

function SM:pop()
  call(self:top(), "exit")
  self.stack[#self.stack] = nil
  call(self:top(), "resume")
end

-- only the top state gets input and time; every state draws, bottom first,
-- so a pause overlay is drawn over the frozen game
function SM:update(dt, input) return call(self:top(), "update", dt, input) end
function SM:keypressed(key) return call(self:top(), "keypressed", key) end
function SM:draw(g)
  for _, s in ipairs(self.stack) do call(s, "draw", g) end
end

return SM
