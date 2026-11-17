-- gsub_fn.lua: three kinds of replacement
local s = "width=1280 height=720"
print((s:gsub("(%a+)=(%d+)", "%2 %1")))           -- string with capture refs

local vars = { user = "arun", home = "/home/arun" }
print((("$user lives in $home ($missing)"):gsub("%$(%w+)", vars)))  -- table lookup

print((s:gsub("%d+", function(n) return tostring(math.floor(tonumber(n) / 2)) end)))  -- function

-- returning nil/false from the function keeps the original match
print((s:gsub("%d+", function(n) if #n > 3 then return "big" end end)))
