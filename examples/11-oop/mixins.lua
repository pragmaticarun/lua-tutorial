-- mixins.lua: share behaviour by copying functions into a class
local Observable = {
  on = function(self, ev, fn)
    self._handlers = self._handlers or {}
    self._handlers[ev] = self._handlers[ev] or {}
    table.insert(self._handlers[ev], fn)
  end,
  emit = function(self, ev, ...)
    for _, fn in ipairs((self._handlers or {})[ev] or {}) do fn(...) end
  end,
}
local Serializable = {
  serialize = function(self)
    local keys = {}
    for k, v in pairs(self) do
      if type(v) ~= "table" and type(v) ~= "function" then keys[#keys + 1] = k end
    end
    table.sort(keys)
    local parts = {}
    for i, k in ipairs(keys) do parts[i] = k .. "=" .. tostring(self[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
  end,
}
local function include(class, mixin)
  for k, v in pairs(mixin) do class[k] = v end
  return class
end

local Player = {}
Player.__index = Player
include(Player, Observable)
include(Player, Serializable)
function Player.new(file) return setmetatable({ file = file, pos = 0 }, Player) end
function Player:seek(pos) self.pos = pos; self:emit("seek", pos) end

local p = Player.new("talk.mkv")
p:on("seek", function(pos) print("seeked to", pos) end)
p:seek(42)
print(p:serialize())
