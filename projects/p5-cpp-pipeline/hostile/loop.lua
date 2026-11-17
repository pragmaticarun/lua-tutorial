-- loop: never returns. The count hook stops it after the instruction budget.
function process(frame)
  local n = 0
  while true do n = n + 1 end
end
