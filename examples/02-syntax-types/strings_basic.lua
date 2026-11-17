-- strings_basic.lua: literals, length, concatenation
local a = 'single'
local b = "double \"escaped\"\ttab"
local c = [[long bracket string:
no escapes \n here]]
local d = [==[can contain ]] safely]==]
print(a); print(b); print(c); print(d)
print("\72\105", "\x48\x69", "\u{48}\u{69}")  -- decimal, hex, UTF-8 escapes
print(#"hello", #"")                           -- # is the length in bytes
print("con" .. "cat" .. 2 .. 3)                -- .. concatenates; numbers coerce
print(tostring(42) == "42", tonumber("0x1F"), tonumber("z", 36), tonumber("nope"))
