-- debug_info.lua: introspection with the debug library
local function scale(width, height, ...)
  local factor = 2
  local info = debug.getinfo(1, "nSlu")        -- level 1 = this function
  local names = {}
  for i = 1, 10 do                             -- locals in declaration order
    local name = debug.getlocal(1, i)
    if not name then break end
    names[#names + 1] = name
  end
  return info, names
end
local info, names = scale(1920, 1080)
print(info.short_src, info.what, info.linedefined, info.currentline)
print("params:", info.nparams, "vararg:", info.isvararg)
print("locals:", table.concat(names, ", "))

local counter = 0
local function bump() counter = counter + 1 end
print(debug.getupvalue(bump, 1))               -- name and value of upvalue 1
debug.setupvalue(bump, 1, 41)                  -- change it from outside
bump()
print(counter)
