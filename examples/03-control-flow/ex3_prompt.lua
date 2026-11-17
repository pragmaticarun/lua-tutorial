-- stdin: ex3_prompt.input
-- Exercise 3 solution: repeat until valid input (a positive number)
local value
repeat
  io.write("enter a positive number: ")
  local line = io.read("l")
  if line == nil then print("\nno more input"); break end
  value = tonumber(line)
  local ok = value ~= nil and value > 0
  if not ok then print("  rejected: " .. line) end
until ok
print("\naccepted:", value)
