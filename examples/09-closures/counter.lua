-- counter.lua: a function that remembers its environment
local function make_counter(step)
  local count = 0                      -- a local of make_counter...
  return function()                    -- ...captured by the inner function
    count = count + step
    return count
  end
end
local by1 = make_counter(1)
local by10 = make_counter(10)
print(by1(), by1(), by1())             -- each closure has its own 'count'
print(by10(), by10())
print(by1())                           -- by1's state was not affected by by10
