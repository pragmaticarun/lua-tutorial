-- logan.args: a small declarative command-line parser.
--
--   local opts, files = args.parse(spec, arg)   -- or nil, message
--
-- spec.options is a list of { short, long, arg = "NAME", default = ...,
-- type = "number", choices = {...}, help = "..." }. Options without `arg`
-- are flags (true/false). Accepted forms: -n 3, -n3, --top 3, --top=3, and
-- "--" ends option parsing (so a file can be called "-x").
local M = {}

local function find(spec, key)
  for _, o in ipairs(spec.options) do
    if key == o[1] or key == o[2] then return o end
  end
end

local function name_of(o) return (o[2] or o[1]):gsub("^%-+", "") end

local function convert(o, value)
  if o.type == "number" then
    local n = tonumber(value)
    if not n then return nil, ("option %s expects a number, got '%s'"):format(o[2] or o[1], value) end
    return n
  end
  if o.choices then
    for _, c in ipairs(o.choices) do if c == value then return value end end
    return nil, ("option %s must be one of %s, got '%s'"):format(o[2] or o[1],
      table.concat(o.choices, ", "), value)
  end
  return value
end

function M.parse(spec, argv)
  local opts, positional = {}, {}
  for _, o in ipairs(spec.options) do
    local key = name_of(o)
    if o.arg then opts[key] = o.default and assert(convert(o, o.default)) else opts[key] = false end
  end
  local i, only_files = 1, false
  while i <= #argv do
    local a = argv[i]
    if only_files or a == "-" or a:sub(1, 1) ~= "-" then
      positional[#positional + 1] = a
    elseif a == "--" then
      only_files = true
    else
      local key, value = a:match("^(%-%-[^=]+)=(.*)$")          -- --top=3
      if not key then
        if a:sub(2, 2) ~= "-" and #a > 2 then key, value = a:sub(1, 2), a:sub(3)  -- -n3
        else key = a end
      end
      local o = find(spec, key)
      if not o then return nil, ("unknown option '%s'"):format(key) end
      if o.arg then
        if value == nil then
          i = i + 1; value = argv[i]
          if value == nil then return nil, ("option %s needs a value (%s)"):format(key, o.arg) end
        end
        local v, err = convert(o, value)
        if v == nil then return nil, err end
        opts[name_of(o)] = v
      else
        if value ~= nil then return nil, ("option %s takes no value"):format(key) end
        opts[name_of(o)] = true
      end
    end
    i = i + 1
  end
  return opts, positional
end

function M.help(spec)
  local lines = { "usage: " .. spec.usage, "" }
  for _, o in ipairs(spec.options) do
    local flags = (o[1] and (o[1] .. ", ") or "    ") .. o[2] .. (o.arg and (" " .. o.arg) or "")
    local help = o.help or ""
    if o.choices then help = help .. ": " .. table.concat(o.choices, ", ") end
    if o.default ~= nil then help = help .. (" (default: %s)"):format(o.default) end
    lines[#lines + 1] = ("  %-22s %s"):format(flags, help)
  end
  return table.concat(lines, "\n")
end

return M
