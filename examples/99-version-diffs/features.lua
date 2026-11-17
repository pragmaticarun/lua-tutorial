-- features.lua: feature detection, the portable way to handle version differences
local function has(expr)
  local f = load("return " .. expr)
  if not f then return "syntax error" end
  local ok, v = pcall(f)
  return ok and v ~= nil
end
local checks = {
  "math.type", "math.ult", "math.pow", "utf8", "string.pack", "table.pack",
  "table.unpack", "unpack", "table.move", "table.create", "setfenv",
  "loadstring", "bit", "jit", "7 // 2", "1 << 4", "coroutine.close", "warn",
}
for _, expr in ipairs(checks) do
  print(string.format("%-16s %s", expr, tostring(has(expr))))
end
