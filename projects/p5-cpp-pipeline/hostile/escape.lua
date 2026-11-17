-- escape: look for ways out of the sandbox. Every name below exists in a
-- normal Lua state (some only in some versions); none should be visible here.
local visible = {}
local candidates = {
  { "os", os }, { "io", io }, { "require", require }, { "load", load },
  { "loadstring", loadstring }, { "dofile", dofile }, { "loadfile", loadfile },
  { "debug", debug }, { "package", package }, { "collectgarbage", collectgarbage },
  { "getmetatable", getmetatable }, { "setfenv", setfenv }, { "getfenv", getfenv },
  { "_G", _G }, { "coroutine", coroutine }, { "jit", jit }, { "module", module },
}
for _, c in ipairs(candidates) do
  if c[2] ~= nil then visible[#visible + 1] = c[1] end
end
print("dangerous globals visible: " .. (#visible == 0 and "none" or table.concat(visible, ", ")))
print("string.dump:", tostring(string.dump), "through a string:", tostring(("").dump))
print("safe parts still work:", ("ab"):rep(3), math.max(3, 7), table.concat({ 1, 2 }, "+"))

function process(frame)
  print("got", tostring(frame), "pixel(0,0) =", frame:get(0, 0))
  local ok, err = pcall(frame.get, frame, 999, 0)
  print("out of range:", ok, err)
end
