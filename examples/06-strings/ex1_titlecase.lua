-- Exercise 1 solution: Title Case each word (ASCII)
local function title_case(s)
  return (s:gsub("(%a)(%w*)", function(first, rest)
    return first:upper() .. rest:lower()
  end))
end
print(title_case("the QUICK brown fox"))
print(title_case("mpv-lua scripting 101"))
