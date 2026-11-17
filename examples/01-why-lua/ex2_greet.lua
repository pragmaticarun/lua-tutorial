-- stdin: ex2_greet.input
-- Exercise 2 solution: greet every non-empty line from stdin
local n = 0
for name in io.lines() do
  if name ~= "" then
    n = n + 1
    print(("Hello, %s! You are visitor #%d."):format(name, n))
  end
end
print(n .. " visitors")
