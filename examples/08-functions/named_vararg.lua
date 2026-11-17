-- targets: 5.5
-- named_vararg.lua: Lua 5.5 can name the vararg table: function f(...args)
local function describe(fmt, ...args)
  print("got " .. args.n .. " extra arguments")
  return string.format(fmt, ...)       -- '...' still works alongside the name
end
print(describe("%s is %d", "answer", 42))

local function last(...t) return t[t.n] end
print(last(1, 2, nil))                 -- n counts trailing nils
local ok, err = load("local function f(...t) t = {} end", "=demo")
print(ok, err)                         -- the name is read-only
