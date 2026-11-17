-- store.lua: bookmark logic with no mpv in it, so it can be tested with any
-- Lua interpreter. A store is a list of { time = seconds, title = string }
-- kept sorted by time.
local M = {}
M.__index = M

M.MERGE = 0.5        -- a new bookmark this close to an old one replaces it

function M.new(list)
  local self = setmetatable({ items = {} }, M)
  for _, b in ipairs(list or {}) do self:add(b.time, b.title) end
  return self
end

function M:count() return #self.items end

-- insert keeping the list sorted; returns the bookmark and whether it was new
function M:add(time, title)
  for _, b in ipairs(self.items) do
    if math.abs(b.time - time) < M.MERGE then
      b.time, b.title = time, title or b.title
      return b, false
    end
  end
  local b = { time = time, title = title or ("Bookmark " .. (#self.items + 1)) }
  local i = #self.items + 1
  while i > 1 and self.items[i - 1].time > time do i = i - 1 end
  table.insert(self.items, i, b)
  return b, true
end

-- remove the bookmark nearest to `time`
function M:remove_near(time)
  local best, dist
  for i, b in ipairs(self.items) do
    local d = math.abs(b.time - time)
    if not dist or d < dist then best, dist = i, d end
  end
  if best then return table.remove(self.items, best) end
end

-- first bookmark after `time` (skipping one we are sitting on), or nil
function M:next_after(time)
  for _, b in ipairs(self.items) do
    if b.time > time + M.MERGE then return b end
  end
  return nil   -- explicit: "no value" and nil differ for select('#') and tostring()
end

function M:prev_before(time)
  for i = #self.items, 1, -1 do
    local b = self.items[i]
    if b.time < time - M.MERGE then return b end
  end
  return nil
end

-- 75.5 -> "01:15.5", 3725 -> "1:02:05.0"
function M.format_time(t)
  local h = math.floor(t / 3600)
  local m = math.floor(t / 60) % 60
  local s = t - math.floor(t / 60) * 60
  if h > 0 then return ("%d:%02d:%04.1f"):format(h, m, s) end
  return ("%02d:%04.1f"):format(m, s)
end

-- the list as text lines, marking the one nearest `now`
function M:lines(now)
  local out, nearest = {}, nil
  for i, b in ipairs(self.items) do
    if not nearest or math.abs(b.time - now) < math.abs(self.items[nearest].time - now) then nearest = i end
  end
  for i, b in ipairs(self.items) do
    out[#out + 1] = ("%s %d. %s  %s"):format(i == nearest and ">" or " ", i, M.format_time(b.time), b.title)
  end
  return out
end

-- mpv's chapter-list property format: { {time=, title=}, ... }
function M:to_chapters()
  local list = {}
  for i, b in ipairs(self.items) do list[i] = { time = b.time, title = b.title } end
  return list
end

-- a simple, diff-friendly file format: one "seconds<TAB>title" per line
function M:serialize()
  local out = {}
  for _, b in ipairs(self.items) do
    out[#out + 1] = ("%.3f\t%s\n"):format(b.time, (b.title:gsub("[\t\n]", " ")))
  end
  return table.concat(out)
end

function M.parse(text)
  local list = {}
  for line in text:gmatch("[^\n]+") do
    local t, title = line:match("^([%d%.]+)\t(.*)$")
    if t then list[#list + 1] = { time = tonumber(t), title = title } end
  end
  return M.new(list)
end

return M
