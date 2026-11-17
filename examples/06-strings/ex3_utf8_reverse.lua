-- targets: 5.5, 5.4
-- Exercise 3 solution: reverse a UTF-8 string by characters, not bytes
local function utf8_reverse(s)
  local chars = {}
  for _, cp in utf8.codes(s) do table.insert(chars, 1, utf8.char(cp)) end
  return table.concat(chars)
end
print(utf8_reverse("añ☕b"))
print(("añ☕b"):reverse() == utf8_reverse("añ☕b"))   -- byte reverse breaks UTF-8
