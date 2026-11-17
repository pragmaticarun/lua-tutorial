-- truthiness.lua: only nil and false are falsy
local function check(label, v)
  if v then print(label, "truthy") else print(label, "falsy") end
end
check("nil  ", nil)
check("false", false)
check("0    ", 0)
check("''   ", "")
check("{}   ", {})

-- 'and'/'or' return one of their operands, not a boolean
print(nil or "default", false or nil, 0 or "never")
print(1 and 2, nil and 2, false and nil)

-- the classic default-argument idiom ...
local function greet(name)
  name = name or "world"
  return "hello, " .. name
end
print(greet(), greet("Lua"))

-- ... and its trap: a legitimate false gets replaced
local opts = { verbose = false }
local verbose = opts.verbose or true        -- BUG: always true
print("verbose:", verbose)
if opts.verbose == nil then verbose = true else verbose = opts.verbose end
print("verbose:", verbose)
