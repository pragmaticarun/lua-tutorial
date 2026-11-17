-- classes.lua: character classes, sets and quantifiers at a glance
local function show(pattern, subject)
  local out = {}
  for m in subject:gmatch(pattern) do out[#out + 1] = "[" .. m .. "]" end
  print(string.format("%-12s %s", pattern, table.concat(out, " ")))
end
local s = "a1 B2_c3  x-9.5"
show("%a", s)        -- letters
show("%d+", s)       -- digit runs
show("%w+", s)       -- alphanumerics
show("[%w_]+", s)    -- a set: identifier characters
show("[^%s]+", s)    -- complement: non-space runs
show("%p", s)        -- punctuation
show("%-?%d+%.?%d*", s)  -- optional sign, digits, optional fraction
show("%a?%d", s)     -- ? = zero or one
