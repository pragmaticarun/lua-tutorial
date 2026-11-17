-- Exercise 3 solution: invert a map (values become keys)
local function invert(t)
  local r = {}
  for k, v in pairs(t) do r[v] = k end
  return r
end
local code_of = { ok = 200, not_found = 404, teapot = 418 }
local name_of = invert(code_of)
print(name_of[404], name_of[418], name_of[500])
