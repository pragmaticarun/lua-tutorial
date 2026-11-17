-- targets: jit
-- luajit_syntax.lua: syntax extensions backported from LuaJIT 3.0 into the
-- rolling LuaJIT 2.1 branch (July 2026, 2.1.1784535649 and later).
-- NOT valid in PUC-Rio Lua, and NOT available in older LuaJIT builds
-- (such as the one bundled with many Neovim/OpenResty releases).
local x = 5
x += 2
print(x, 1 << 4, 0xff & 0x0f, ~0)
local t = nil
print(t?.a, t ?? "default", x > 3 ? "big" : "small")
for i = 1, 5 do
  if i % 2 == 0 then continue end
  io.write(i, " ")
end
print()
print(1_000_000, x != 7, !false, true && false || true)
local f = |a, b| -> a + b
print(f(2, 3))
const LIMIT = 3                       -- LuaJIT's spelling of a constant local
print(LIMIT, load("const y = 1; y = 2"))
