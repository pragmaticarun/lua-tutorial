-- module
-- Run inside each Part 4 host by host_dialects.test.sh: which Lua dialect
-- does the host really give you? rawget avoids Redis's "nonexistent global"
-- error for names a host does not define.
local G = _G
local compile = rawget(G, "loadstring") or rawget(G, "load")
local require_ = rawget(G, "require")
local jit_ = rawget(G, "jit")
local function compiles(src)
  return compile(src) ~= nil
end
local out = {}
local function row(k, v)
  out[#out + 1] = ("  %-34s %s"):format(k, tostring(v))
end
row("_VERSION", _VERSION)
row("jit.version", jit_ and jit_.version or "(no jit)")
row("math.type (integer subtype)", math.type ~= nil)
row("// floor division compiles", compiles("return 7 // 2"))
row("& bitwise operator compiles", compiles("return 6 & 3"))
row("bit library", rawget(G, "bit") ~= nil or (require_ ~= nil and pcall(require_, "bit")))
row("goto compiles", compiles("goto done ::done::"))
row("x += 1 (LuaJIT 2026 backport)", compiles("local x = 1 x += 1"))
row("<const> attribute compiles", compiles("local x <const> = 1"))
row("table.unpack / unpack", tostring(table.unpack ~= nil) .. " / " .. tostring(rawget(G, "unpack") ~= nil))
row("ffi available", require_ ~= nil and (pcall(require_, "ffi")))
return table.concat(out, "\n")
