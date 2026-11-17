-- Exercise 3 solution: the biggest win is usually algorithmic
local bench = require("bench")

local function fib(n) if n < 2 then return n end return fib(n - 1) + fib(n - 2) end

local function fib_memo(n)
  local memo = { [0] = 0, [1] = 1 }
  local function f(k)
    local v = memo[k]
    if v == nil then v = f(k - 1) + f(k - 2); memo[k] = v end
    return v
  end
  return f(n)
end

bench.compare("ex3 fibonacci(27)", {
  { "naive recursion", function() return fib(27) end },
  { "memoized", function() return fib_memo(27) end },
})
