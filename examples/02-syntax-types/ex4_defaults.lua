-- Exercise 4 solution: defaults that respect an explicit false
local function opt(value, default)
  if value == nil then return default end
  return value
end
local config = { verbose = false, level = nil }
print("verbose:", opt(config.verbose, true))   -- keeps the explicit false
print("level:", opt(config.level, 3))          -- missing -> default
print("buggy verbose:", config.verbose or true) -- the 'or' trap
