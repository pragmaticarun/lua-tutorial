-- module
local M = {}

function M.slug(s, sep)
  sep = sep or "-"
  return (s:lower():gsub("%W+", sep):gsub("^%" .. sep .. "+", ""):gsub("%" .. sep .. "+$", ""))
end

return M
