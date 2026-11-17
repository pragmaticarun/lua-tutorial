-- levels.lua: the level argument of error() chooses whose line is blamed
local function check_positive(n, level)
  if n <= 0 then error("expected a positive number", level) end
  return n
end
local function caller(level)
  local v = check_positive(-1, level)          -- line 7 (not a tail call)
  return v
end

print(pcall(caller, 1))   -- level 1 (default): the line that called error()
print(pcall(caller, 2))   -- level 2: the caller of check_positive
print(pcall(caller, 0))   -- level 0: no position at all
