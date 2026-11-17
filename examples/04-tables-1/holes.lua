-- holes.lua: what is #t when the "array" has holes?
local cases = {
  { name = "{1, nil, 3}",          t = { 1, nil, 3 } },
  { name = "{1, 2, nil, 4}",       t = { 1, 2, nil, 4 } },
  { name = "{nil, nil, 3}",        t = { nil, nil, 3 } },
  { name = "{1..5}, then [3]=nil", t = (function()
                                      local t = { 1, 2, 3, 4, 5 }; t[3] = nil; return t
                                    end)() },
  { name = "{1, 2, 3}, then [5]=5", t = (function()
                                      local t = { 1, 2, 3 }; t[5] = 5; return t
                                    end)() },
}
for _, c in ipairs(cases) do
  print(string.format("%-24s #t = %d", c.name, #c.t))
end
