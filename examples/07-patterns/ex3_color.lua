-- Exercise 3 solution: validate and decode #RRGGBB colours
local function parse_color(s)
  local r, g, b = s:match("^#(%x%x)(%x%x)(%x%x)$")
  if not r then return nil, "bad colour: " .. s end
  return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
end
print(parse_color("#FF8800"))
print(parse_color("#ff880"))
print(parse_color("#GG0000"))
