-- firstclass.lua: functions are values like any other
local function square(x) return x * x end   -- sugar for: local square; square = function(x) ... end
local twice = function(f, x) return f(f(x)) end

print(twice(square, 3))                      -- pass a function as an argument
print(twice(function(x) return x + 10 end, 1))  -- anonymous function

local ops = {                                -- functions stored in a table
  add = function(a, b) return a + b end,
  mul = function(a, b) return a * b end,
}
for _, name in ipairs({ "add", "mul" }) do print(name, ops[name](6, 7)) end

local p = print                              -- functions can be aliased...
p("aliased print", type(p), p == print)      -- ...and compared by identity
