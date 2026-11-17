-- debug_hook.lua: line hooks - the building block of debuggers and profilers
local function work(n)
  local s = 0
  for i = 1, n do
    s = s + i
  end
  return s
end
local lines = {}
debug.sethook(function(event, line)
  if debug.getinfo(2, "S").short_src == "debug_hook.lua" then
    lines[#lines + 1] = line
  end
end, "l")
work(2)
debug.sethook()                                -- remove the hook
print(table.concat(lines, " "))
