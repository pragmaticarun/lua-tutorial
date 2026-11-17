-- Exercise 2: a fixed-timestep accumulator. Whatever the frame times are,
-- the simulation advances in identical 1/60 s steps, so the result depends
-- only on total time; alpha is left over for interpolated drawing.
local STEP = 1 / 60

local function simulate(frame_times)
  local acc, steps, x, vx = 0, 0, 0, 30          -- x moves 30 px/s
  local prev_x, alpha = 0, 0
  for _, dt in ipairs(frame_times) do
    acc = acc + math.min(dt, 0.25)               -- avoid the "spiral of death"
    while acc >= STEP do
      prev_x = x
      x = x + vx * STEP
      acc = acc - STEP
      steps = steps + 1
    end
    alpha = acc / STEP
  end
  local drawn = prev_x + (x - prev_x) * alpha    -- what you would draw
  return steps, x, drawn
end

local smooth, jittery, slow = {}, {}, {}
for i = 1, 60 do smooth[i] = 1 / 60 end
for i = 1, 30 do jittery[i] = (i % 2 == 0) and 0.02 or (2 / 60 - 0.02) end
for i = 1, 6 do slow[i] = 1 / 6 end              -- 6 fps
local partial = { 1 / 60, 1 / 60, 1 / 120 }      -- ends half-way into a step
for _, case in ipairs({ { "smooth", smooth }, { "jittery", jittery }, { "slow", slow },
                        { "partial", partial } }) do
  local name, frames = case[1], case[2]
  local steps, x, drawn = simulate(frames)
  print(("%-8s frames=%2d steps=%d x=%.2f drawn=%.2f"):format(name, #frames, steps, x, drawn))
end
