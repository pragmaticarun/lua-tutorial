-- float_print.lua: how floats are turned into text
print(0.1 + 0.2, 1 / 3, 3.14)
print(0.1 + 0.2 == 0.3)
print(string.format("%.2f", 0.1 + 0.2))       -- explicit formatting is stable
print(tonumber(tostring(1 / 3)) == 1 / 3)      -- does text round-trip?
