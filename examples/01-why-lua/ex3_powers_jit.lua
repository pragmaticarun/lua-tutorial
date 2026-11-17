-- targets: jit
-- Exercise 3 solution for LuaJIT builds older than mid-2026 (no << operator): use the bit library
for i = 0, 10, 2 do
  print(i, 2^i, bit.lshift(1, i))
end
