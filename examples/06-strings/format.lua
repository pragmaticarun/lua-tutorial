-- format.lua: string.format follows C printf, plus %q
print(string.format("[%5d] [%-5d] [%05d]", 42, 42, 42))
print(string.format("[%8.3f] [%.2e] [%g] [%g]", math.pi, 123456.789, 0.0001, 1e20))
print(string.format("[%10s] [%-10s] [%.3s]", "right", "left", "truncate"))
print(string.format("%x %X %#x %o", 255, 255, 255, 8))
print(string.format("%c%c%c", 76, 117, 97))
print(string.format("%s %s %s", nil, true, { 1 } ~= nil))   -- %s calls tostring
print(string.format("%q", 'say "hi"\n\tbye'))                  -- a Lua-readable literal
print(string.format("%5.1f%%", 99.44))                         -- literal percent
