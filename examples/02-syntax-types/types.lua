-- types.lua: Lua has eight basic types; type() names them
local values = { true, 42, 3.14, "hi", {}, print, coroutine.create(print) }
print(type(nil))               -- nil can't live inside a table literal list safely
for i = 1, #values do
  print(type(values[i]))
end
-- the eighth type, userdata, comes from C: io.stdout is one
print(type(io.stdout))
