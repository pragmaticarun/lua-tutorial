-- Exercise 1 solution: a Stack class
local Stack = {}
Stack.__index = Stack
Stack.__len = function(s) return s.n end            -- used by 5.2+ only
function Stack.new() return setmetatable({ n = 0, items = {} }, Stack) end
function Stack:push(v) self.n = self.n + 1; self.items[self.n] = v; return self end
function Stack:pop()
  if self.n == 0 then return nil, "empty" end
  local v = self.items[self.n]
  self.items[self.n] = nil
  self.n = self.n - 1
  return v
end
function Stack:peek() return self.items[self.n] end
function Stack:size() return self.n end              -- portable alternative to #

local s = Stack.new():push("a"):push("b"):push("c")
print(s:size(), s:peek())
print(s:pop(), s:pop(), s:pop(), s:pop())
