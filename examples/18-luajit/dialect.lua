-- dialect.lua: Lua 5.1 (LuaJIT) vs Lua 5.4/5.5 - detect, don't assume
local function supports(src)            -- does this chunk compile?
  return (load(src)) ~= nil
end
print(_VERSION, jit and jit.version or "no jit module")
print("integers (math.type):", math.type ~= nil)
print("// operator:", supports("return 7 // 2"))
print("bit ops & | ~:", supports("return 6 & 3"), "bit library:", bit ~= nil)
print("goto:", supports("goto done ::done::"))
print("\\u{...} escapes:", supports([[return "\u{48}"]]))
print("table.unpack:", table.unpack ~= nil, "global unpack:", unpack ~= nil)
print("_ENV:", supports("local _ENV = {} return x") and _ENV ~= nil,
      "setfenv:", setfenv ~= nil)
print("<close>:", supports("local x <close> = nil"))
print("utf8 library:", utf8 ~= nil)
-- precision: LuaJIT numbers are doubles, 5.3+ has 64-bit integers
print("2^53 + 1 exact:", math.type ~= nil and (9007199254740992 + 1) % 2 == 1)
