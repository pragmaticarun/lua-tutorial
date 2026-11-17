-- targets: 5.5
-- global_decl.lua: Lua 5.5 global declarations make typos compile errors
-- load() compiles a string; on a compile error it returns nil + message.
local function try(src)
  local fn, err = load(src, "=demo")
  if not fn then return print("compile error:", err) end
  local ok, res = pcall(fn)
  print(ok and "ran ok:" or "runtime error:", res)
end

-- 1. Any explicit 'global' declaration switches off the implicit 'global *':
try [[
  global print            -- we will use this global
  local sum = 1
  print(summ)             -- typo: not declared, so this does not compile
]]

-- 2. 'global<const> *' = read any global, assign none (except declared ones)
try [[
  global<const> *
  global counter
  counter = 1             -- fine, declared read-write
  math = nil              -- error: read-only
]]

-- 3. Initialising a global that already has a value is a run-time error
try [[
  global *
  global print = function() end
]]

-- 4. 'global function' declares and defines in one go
try [[
  global *
  global function area(w, h) return w * h end
  return area(3, 4)
]]
