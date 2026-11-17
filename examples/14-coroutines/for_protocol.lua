-- for_protocol.lua: what 'for k, v in explist' really does
-- explist yields: an iterator function f, an invariant state s, a control value c.
-- Each step calls f(s, c); the loop ends when the first result is nil.
local function iter(t, i)            -- a STATELESS iterator: all state is in (t, i)
  i = i + 1
  local v = t[i]
  if v ~= nil then return i, v end
end
local function my_ipairs(t) return iter, t, 0 end

for i, v in my_ipairs({ "I", "P", "B" }) do io.write(i, "=", v, " ") end
print()

-- the same loop written by hand
local f, s, c = my_ipairs({ "x", "y" })
while true do
  local i, v = f(s, c)
  if i == nil then break end
  c = i
  io.write(i, "=", v, " ")
end
print()

-- pairs is just next: next(t, k) returns the key after k
local t = { only = 1 }
print(next(t), next(t, "only"), next({}))
