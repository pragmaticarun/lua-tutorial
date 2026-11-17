-- tailcall.lua: proper tail calls never grow the stack
local function count_down(n, acc)
  if n == 0 then return acc end
  return count_down(n - 1, acc + 1)    -- a tail call: 'return f(...)'
end
print(count_down(1000000, 0))           -- a million calls, constant stack

local function not_tail(n)
  if n == 0 then return 0 end
  return 1 + not_tail(n - 1)            -- NOT a tail call: '1 +' runs afterwards
end
local ok = pcall(not_tail, 1000000)
print("non-tail recursion, depth 1e6, ok?", ok)
