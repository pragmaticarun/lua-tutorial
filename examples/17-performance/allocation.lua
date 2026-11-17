-- allocation.lua: temporary tables in a hot loop vs multiple return values
local bench = require("bench")
local N = 500000

local function add_t(a, b) return { x = a.x + b.x, y = a.y + b.y } end
local function add_xy(ax, ay, bx, by) return ax + bx, ay + by end

bench.compare("vector maths", {
  { "new table per add", function()
      local p, v = { x = 0, y = 0 }, { x = 1, y = 2 }
      for _ = 1, N do p = add_t(p, v) end
      return p.x + p.y
    end },
  { "multiple returns", function()
      local px, py = 0, 0
      for _ = 1, N do px, py = add_xy(px, py, 1, 2) end
      return px + py
    end },
})
