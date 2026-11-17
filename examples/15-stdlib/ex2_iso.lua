-- Exercise 2 solution: ISO-8601 timestamps and human durations
local function iso_utc(t) return os.date("!%Y-%m-%dT%H:%M:%SZ", t) end
local function human(seconds)
  local parts = {}
  for _, unit in ipairs({ { "d", 86400 }, { "h", 3600 }, { "m", 60 }, { "s", 1 } }) do
    local n = math.floor(seconds / unit[2])
    if n > 0 then parts[#parts + 1] = n .. unit[1]; seconds = seconds - n * unit[2] end
  end
  return #parts > 0 and table.concat(parts, " ") or "0s"
end
print(iso_utc(0), iso_utc(1794386141))
print(human(95), human(3725), human(90061), human(0))
