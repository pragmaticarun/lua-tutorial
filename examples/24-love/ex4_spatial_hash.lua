-- Exercise 4: a spatial hash broad phase. Only objects sharing a grid cell
-- are tested pairwise; compare the number of checks with brute force.
local CELL = 32

local function overlaps(a, b)
  return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

local function build(objs)
  local grid = {}
  for id, o in ipairs(objs) do
    -- math.floor, not //: LuaJIT (LÖVE's Lua) has no floor-division operator
    for cx = math.floor(o.x / CELL), math.floor((o.x + o.w - 1) / CELL) do
      for cy = math.floor(o.y / CELL), math.floor((o.y + o.h - 1) / CELL) do
        local key = cx .. "," .. cy
        local cell = grid[key] or {}
        grid[key] = cell
        cell[#cell + 1] = id
      end
    end
  end
  return grid
end

local function pairs_hashed(objs)
  local seen, hits, checks = {}, {}, 0
  for _, cell in pairs(build(objs)) do
    for i = 1, #cell do
      for j = i + 1, #cell do
        local a, b = math.min(cell[i], cell[j]), math.max(cell[i], cell[j])
        local k = a * 100000 + b
        if not seen[k] then
          seen[k] = true; checks = checks + 1
          if overlaps(objs[a], objs[b]) then hits[#hits + 1] = a .. "-" .. b end
        end
      end
    end
  end
  table.sort(hits)
  return hits, checks
end

local function pairs_brute(objs)
  local hits, checks = {}, 0
  for a = 1, #objs do
    for b = a + 1, #objs do
      checks = checks + 1
      if overlaps(objs[a], objs[b]) then hits[#hits + 1] = a .. "-" .. b end
    end
  end
  table.sort(hits)
  return hits, checks
end

-- 200 boxes on a 640x480 field from a deterministic generator
local objs, s = {}, 7
local function rnd(n) s = (s * 16807) % 2147483647; return s % n end
for i = 1, 200 do objs[i] = { x = rnd(620), y = rnd(460), w = 8 + rnd(12), h = 8 + rnd(12) } end

local h1, c1 = pairs_brute(objs)
local h2, c2 = pairs_hashed(objs)
print("brute force: " .. #h1 .. " overlaps, " .. c1 .. " checks")
print("spatial hash: " .. #h2 .. " overlaps, " .. c2 .. " checks")
print("same pairs:", table.concat(h1, ",") == table.concat(h2, ","))
