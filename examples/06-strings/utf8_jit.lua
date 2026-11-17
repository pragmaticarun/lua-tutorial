-- utf8_jit.lua: counting UTF-8 characters without the utf8 library (works everywhere)
-- one character = a lead byte followed by any continuation bytes (0x80-0xBF)
local s = "naïve café ☕"
local count = 0
for ch in s:gmatch("[^\128-\191][\128-\191]*") do count = count + 1 end
print("bytes:", #s, "characters:", count)
local chars = {}
for ch in s:gmatch("[^\128-\191][\128-\191]*") do chars[#chars + 1] = ch end
print(chars[3], chars[12])
