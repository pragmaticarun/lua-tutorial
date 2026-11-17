-- local_function.lua: recursion needs 'local function' (or a forward declaration)
local function fact(n)                 -- = local fact; fact = function ...
  if n <= 1 then return 1 end
  return n * fact(n - 1)
end
print(fact(10))

local broken = function(n)             -- 'broken' is not in scope inside its own body
  if n <= 1 then return 1 end
  return n * broken(n - 1)             -- refers to a GLOBAL named broken (nil)
end
print(pcall(broken, 3))

local is_even, is_odd                  -- forward declaration for mutual recursion
function is_even(n) if n == 0 then return true else return is_odd(n - 1) end end
function is_odd(n) if n == 0 then return false else return is_even(n - 1) end end
print(is_even(10), is_odd(7))
