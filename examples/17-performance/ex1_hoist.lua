-- Exercise 1 solution: speed up a per-sample audio gain loop
local bench = require("bench")
local N = 500000
local cfg = { gain = 0.5, clip = 1.0 }
local samples = {}
for i = 1, N do samples[i] = ((i * 7919) % 2001 - 1000) / 500 end

bench.compare("ex1 gain loop", {
  { "slow: globals, table.insert, repeated field lookups", function()
      local out = {}
      for i = 1, #samples do
        local v = samples[i] * cfg.gain
        if v > cfg.clip then v = cfg.clip elseif v < -cfg.clip then v = -cfg.clip end
        table.insert(out, math.floor(v * 32767))
      end
      return out[1] + out[#out] + #out
    end },
  { "fast: hoisted locals, direct index", function()
      local floor, gain, clip = math.floor, cfg.gain, cfg.clip
      local out, n = {}, #samples
      for i = 1, n do
        local v = samples[i] * gain
        if v > clip then v = clip elseif v < -clip then v = -clip end
        out[i] = floor(v * 32767)
      end
      return out[1] + out[#out] + #out
    end },
})
