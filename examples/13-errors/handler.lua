-- handler.lua: a custom message handler that enriches errors
local function handler(err)
  local info = debug.getinfo(2, "Sl")        -- the function that raised the error
  return { message = tostring(err), where = info.short_src .. ":" .. info.currentline }
end
local function risky() local t = {}; return t.missing.field end
local ok, e = xpcall(risky, handler)
print(ok, e.where)
print(e.message)
