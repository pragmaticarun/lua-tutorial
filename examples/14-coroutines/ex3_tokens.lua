-- Exercise 3 solution: a token generator for "key=value; key2='quoted value'"
local function tokens(s)
  return coroutine.wrap(function()
    local pos = 1
    while pos <= #s do
      local ws = s:match("^%s+", pos)
      if ws then pos = pos + #ws
      else
        local q = s:match("^'([^']*)'", pos)
        if q then coroutine.yield("string", q); pos = pos + #q + 2
        else
          local w = s:match("^[%w_%.]+", pos)
          if w then coroutine.yield("word", w); pos = pos + #w
          else coroutine.yield("punct", s:sub(pos, pos)); pos = pos + 1 end
        end
      end
    end
  end)
end
for kind, text in tokens("codec=av1; title='My Talk'; crf=30") do
  print(("%-6s %s"):format(kind, text))
end
