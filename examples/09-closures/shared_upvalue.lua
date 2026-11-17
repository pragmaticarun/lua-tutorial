-- shared_upvalue.lua: closures created together share the same variable
local function make_volume(initial)
  local level = initial
  local function get() return level end
  local function set(v)
    if v < 0 then v = 0 elseif v > 100 then v = 100 end
    level = v
  end
  return get, set
end
local get, set = make_volume(50)
set(80); print(get())
set(150); print(get())                 -- clamped: 'level' is private
print(level)                           -- nil: no way to reach it from outside
