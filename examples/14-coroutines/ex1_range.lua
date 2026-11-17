-- Exercise 1 solution: a stateless range iterator (no closure allocated)
local function step_iter(state, i)
  i = i + state.step
  if (state.step > 0 and i <= state.stop) or (state.step < 0 and i >= state.stop) then
    return i
  end
end
local function range(start, stop, step)
  local state = { stop = stop, step = step or 1 }
  return step_iter, state, start - state.step
end
for i in range(1, 5) do io.write(i, " ") end print()
for i in range(10, 1, -3) do io.write(i, " ") end print()
