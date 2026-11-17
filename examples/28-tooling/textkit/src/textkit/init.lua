-- module
--- textkit: small text helpers, packaged with LuaRocks.
-- Works on Lua 5.1-5.5 and LuaJIT: no goto, no //, no integer-only APIs.
local wrap = require("textkit.wrap")

local M = { _VERSION = "0.1.0", wrap = wrap.wrap }

--- Remove leading and trailing whitespace.
---@param s string
---@return string
function M.trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Lower-case, ASCII-only, words joined by "-".
---@param s string
---@return string
function M.slugify(s)
  local slug = s:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
  return slug
end

--- Split on a plain (non-pattern) separator, keeping empty fields.
---@param s string
---@param sep string
---@return string[]
function M.split(s, sep)
  assert(sep ~= "", "separator must not be empty")
  local out, start = {}, 1
  while true do
    local i, j = s:find(sep, start, true)
    if not i then
      out[#out + 1] = s:sub(start)
      return out
    end
    out[#out + 1] = s:sub(start, i - 1)
    start = j + 1
  end
end

return M
