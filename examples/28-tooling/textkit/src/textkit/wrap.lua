-- module
--- Greedy word wrapping.
local M = {}

--- Wrap text to lines of at most `width` characters (longer words stay whole).
---@param text string
---@param width integer
---@return string[]
function M.wrap(text, width)
  assert(type(width) == "number" and width > 0, "width must be a positive number")
  local lines, line = {}, nil
  for word in text:gmatch("%S+") do
    if line == nil then
      line = word
    elseif #line + 1 + #word <= width then
      line = line .. " " .. word
    else
      lines[#lines + 1] = line
      line = word
    end
  end
  lines[#lines + 1] = line
  return lines
end

return M
