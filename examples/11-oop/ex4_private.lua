-- Exercise 4 solution: closure-based object with private state and validation
local function new_volume(initial)
  local level, muted = initial or 50, false
  local obj = {}
  function obj.set(v) level = math.max(0, math.min(100, v)) end
  function obj.toggle_mute() muted = not muted end
  function obj.effective() return muted and 0 or level end
  return obj
end
local vol = new_volume(70)
vol.set(130)
print(vol.effective())
vol.toggle_mute()
print(vol.effective(), vol.level)
