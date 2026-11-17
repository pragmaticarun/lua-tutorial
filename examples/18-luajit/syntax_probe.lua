-- syntax_probe.lua: the LuaJIT 2.1 branch accepted new syntax in July 2026
local probes = {
  { "compound assignment", "local x = 1; x += 2; return x" },
  { "continue",            "for i = 1, 2 do continue end" },
  { "nil-coalescing ??",   "local a; return a ?? 1" },
  { "safe navigation ?.",  "local t; return t?.x" },
  { "ternary ?:",          "return true ? 1 : 2" },
  { "const x = ...",       "const x = 1; return x" },
  { "short lambda",        "local f = |a, b| -> a + b; return f(1, 2)" },
  { "1_000_000",           "return 1_000_000" },
  { "!= operator",         "return 1 != 2" },
  { "// floor division",   "return 7 // 2" },
}
for _, p in ipairs(probes) do
  local f = load(p[2])
  print(("%-20s %s"):format(p[1], f and "yes" or "no"))
end
