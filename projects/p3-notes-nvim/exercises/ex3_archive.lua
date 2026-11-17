-- Exercise 3 (solution): move finished tasks into a "## Done" section at
-- the end of the file (created if needed), keeping everything else in place.
package.path = "../lua/?.lua;../lua/?/init.lua;" .. package.path
local tasks = require("notes.tasks")

local function archive(lines)
  local keep, done, done_header = {}, {}, nil
  for i, line in ipairs(lines) do
    local t = tasks.parse(line, i)
    if line:match("^##%s+Done%s*$") then
      done_header = true
      keep[#keep + 1] = line
    elseif t and t.done and not done_header then
      done[#done + 1] = line
    else
      keep[#keep + 1] = line
    end
  end
  if #done == 0 then return keep, 0 end
  if not done_header then
    if keep[#keep] ~= "" then keep[#keep + 1] = "" end
    keep[#keep + 1] = "## Done"
    keep[#keep + 1] = ""
  end
  for _, l in ipairs(done) do keep[#keep + 1] = l end
  return keep, #done
end

local out, n = archive({ "## Tasks", "", "- [x] fix build", "- [ ] ship", "- [x] tag release" })
print("archived " .. n)
for _, l in ipairs(out) do print("| " .. l) end
