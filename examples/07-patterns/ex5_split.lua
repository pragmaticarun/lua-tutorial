-- Exercise 5 solution: split on a literal separator, keeping empty fields
local function split(s, sep)
  local out, pos = {}, 1
  while true do
    local i, j = s:find(sep, pos, true)        -- plain find: sep is not a pattern
    if not i then out[#out + 1] = s:sub(pos); return out end
    out[#out + 1] = s:sub(pos, i - 1)
    pos = j + 1
  end
end
local fields = split("a.b..c.", ".")
print(#fields, "[" .. table.concat(fields, "][") .. "]")
print(table.concat(split("key: value: more", ": "), " | "))
