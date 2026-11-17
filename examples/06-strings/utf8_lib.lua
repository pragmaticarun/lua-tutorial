-- targets: 5.5, 5.4
-- utf8_lib.lua: Lua strings are bytes; the utf8 library understands UTF-8
local s = "naïve café ☕"
print("bytes:", #s, "code points:", utf8.len(s))
print(utf8.char(72, 228, 8364, 9749))              -- code points -> UTF-8 text
print(utf8.codepoint(s, 3))                         -- 'ï' starts at byte 3
for pos, cp in utf8.codes("añ☕") do
  print(pos, cp, utf8.char(cp))
end
print(utf8.offset(s, 7))                            -- byte offset of 7th character
print(utf8.len("\xff"))                             -- invalid UTF-8: nil + position
-- string.upper is byte-based and ASCII-only:
print(("café"):upper())
