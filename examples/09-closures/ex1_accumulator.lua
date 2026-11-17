-- Exercise 1 solution: an accumulator with add, and a reset that shares state
local function make_acc(start)
  local total = start or 0
  return {
    add = function(x) total = total + x; return total end,
    reset = function() total = start or 0 end,
  }
end
local a = make_acc(100)
print(a.add(5), a.add(10))
a.reset()
print(a.add(1))
