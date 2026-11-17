-- Exercise 2 solution: trim, and why the obvious pattern can be slow
local function trim(s)
  return (s:match("^%s*(.-)%s*$"))
end
local function trim_fast(s)                   -- no backtracking on long runs of spaces
  local from = s:match("^%s*()")
  return from > #s and "" or s:match(".*%S", from)
end
for _, s in ipairs({ "  padded  ", "\tnone\n", "   ", "x" }) do
  print(("%q %q %q"):format(s, trim(s), trim_fast(s)))
end
