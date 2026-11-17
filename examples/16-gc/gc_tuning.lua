-- gc_tuning.lua: the tuning knobs differ in every implementation
local v = _VERSION .. (jit and " (LuaJIT)" or "")
print(v)
if _VERSION == "Lua 5.5" then
  -- Lua 5.5: one "param" option; returns the previous value
  print("pause", collectgarbage("param", "pause"))
  print("stepmul", collectgarbage("param", "stepmul"))
  print("minormul", collectgarbage("param", "minormul"))
  print("set pause 150, old:", collectgarbage("param", "pause", 150))
  collectgarbage("param", "pause", 250)
else
  -- Lua 5.1 - 5.4 and LuaJIT: setpause / setstepmul return the previous value
  local old = collectgarbage("setpause", 150)
  print("pause", old)
  local mul = collectgarbage("setstepmul", 200)
  print("stepmul", mul)
  collectgarbage("setpause", old); collectgarbage("setstepmul", mul)
end
