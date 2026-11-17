-- logan.report: aggregate records, then render them as text or JSON.
local M = {}

local function bump(t, k, n) t[k] = (t[k] or 0) + (n or 1) end

function M.new()
  return { lines = 0, parsed = 0, bad = {}, bytes = 0,
           status = {}, class = {}, paths = {}, ips = {}, levels = {},
           components = {}, minutes = {}, errors = 0 }
end

-- feed one line's parse result into the statistics
function M.add(st, rec, where)      -- where = "file:line"
  st.lines = st.lines + 1
  if not rec then
    if #st.bad < 5 then st.bad[#st.bad + 1] = where end   -- remember the first few
    return
  end
  st.parsed = st.parsed + 1
  bump(st.minutes, rec.minute)
  if rec.kind == "access" then
    bump(st.status, rec.status)
    bump(st.class, math.floor(rec.status / 100) .. "xx")
    bump(st.paths, rec.path)
    bump(st.ips, rec.ip)
    st.bytes = st.bytes + rec.bytes
    if rec.status >= 500 then st.errors = st.errors + 1 end
  else
    bump(st.levels, rec.level)
    bump(st.components, rec.component)
    if rec.level == "ERROR" then st.errors = st.errors + 1 end
  end
end

-- the n biggest counts; ties sorted by key so the output is deterministic
function M.top(counts, n)
  local list = {}
  for k, v in pairs(counts) do list[#list + 1] = { key = k, count = v } end
  table.sort(list, function(a, b)
    if a.count ~= b.count then return a.count > b.count end
    return tostring(a.key) < tostring(b.key)
  end)
  for i = #list, (n or #list) + 1, -1 do list[i] = nil end
  return list
end

local function sorted_keys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  return keys
end

function M.text(st, n)
  local out = {}
  local function say(fmt, ...) out[#out + 1] = fmt:format(...) end
  say("lines: %d  parsed: %d  unparsed: %d  errors: %d", st.lines, st.parsed, st.lines - st.parsed, st.errors)
  if #st.bad > 0 then say("first unparsed lines: %s", table.concat(st.bad, ", ")) end
  local function section(title, counts)
    if next(counts) == nil then return end
    say("")
    say("%s", title)
    for _, e in ipairs(M.top(counts, n)) do say("  %-24s %6d", tostring(e.key), e.count) end
  end
  if next(st.class) then
    local parts = {}
    for _, k in ipairs(sorted_keys(st.class)) do parts[#parts + 1] = ("%s=%d"):format(k, st.class[k]) end
    say("status classes: %s  bytes: %d", table.concat(parts, " "), st.bytes)
  end
  section("top paths", st.paths)
  section("top clients", st.ips)
  section("levels", st.levels)
  section("components", st.components)
  -- requests per minute as a bar chart, scaled to 30 columns
  local peak = 0
  for _, c in pairs(st.minutes) do if c > peak then peak = c end end
  if peak > 0 then
    say("")
    say("per minute")
    for _, m in ipairs(sorted_keys(st.minutes)) do
      local c = st.minutes[m]
      say("  %s %4d %s", m, c, ("#"):rep(math.max(1, math.floor(c * 30 / peak + 0.5))))
    end
  end
  return table.concat(out, "\n")
end

-- A minimal JSON encoder: enough for our report (strings, integers, arrays
-- and objects with string keys, written with sorted keys).
local function encode(v)
  local t = type(v)
  if t == "table" then
    if #v > 0 or next(v) == nil then
      local parts = {}
      for i = 1, #v do parts[i] = encode(v[i]) end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    local parts = {}
    for _, k in ipairs(sorted_keys(v)) do parts[#parts + 1] = encode(tostring(k)) .. ":" .. encode(v[k]) end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif t == "string" then
    return '"' .. v:gsub('[%c"\\]', function(c)
      return ({ ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\t"] = "\\t" })[c]
        or ("\\u%04x"):format(c:byte())
    end) .. '"'
  elseif t == "number" then
    return v == math.floor(v) and ("%d"):format(v) or ("%.3f"):format(v)
  elseif t == "boolean" then
    return tostring(v)
  end
  return "null"
end
M.encode = encode

function M.json(st, n)
  local function top(counts)
    local list = {}
    for i, e in ipairs(M.top(counts, n)) do list[i] = { key = tostring(e.key), count = e.count } end
    return list
  end
  return encode({
    lines = st.lines, parsed = st.parsed, errors = st.errors, bytes = st.bytes,
    unparsed_lines = st.bad, classes = st.class,
    top_paths = top(st.paths), top_clients = top(st.ips),
    levels = st.levels, per_minute = st.minutes,
  })
end

return M
