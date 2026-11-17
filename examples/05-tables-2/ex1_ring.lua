-- Exercise 1 solution: fixed-capacity ring buffer (e.g. last N frame times)
local Ring = {}
function Ring.new(cap) return { cap = cap, head = 0, count = 0, items = {} } end
function Ring.push(r, v)
  r.head = r.head % r.cap + 1           -- 1..cap, wrapping around
  r.items[r.head] = v
  if r.count < r.cap then r.count = r.count + 1 end
end
function Ring.values(r)                 -- oldest first
  local out = {}
  local start = (r.head - r.count) % r.cap
  for i = 1, r.count do out[i] = r.items[(start + i - 1) % r.cap + 1] end
  return out
end
local r = Ring.new(3)
for ms = 16, 21 do Ring.push(r, ms) end
print(table.concat(Ring.values(r), " "))
local sum = 0
for _, v in ipairs(Ring.values(r)) do sum = sum + v end
print(("avg: %.1f ms"):format(sum / r.count))
