-- pcall_loop: tries to swallow the limit error and keep running. The host's
-- pcall re-raises once the budget is spent, so this still stops.
function process(frame)
  while true do
    pcall(function() while true do end end)
  end
end
