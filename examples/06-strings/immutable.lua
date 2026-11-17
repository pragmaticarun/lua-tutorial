-- immutable.lua: strings are immutable values
local s = "frame"
local t = s:upper()            -- method syntax: same as string.upper(s)
print(s, t)                    -- s is unchanged; upper() returned a new string

local a = "fr" .. "ame"
print(a == s)                  -- strings compare by value, not identity

-- building a big string: collect pieces, then join once
local parts = {}
for i = 1, 5 do parts[#parts + 1] = "f" .. i end
print(table.concat(parts, "|"))

-- every value of type string shares the 'string' library as its methods
print(("%d frames"):format(24), ("abc"):len(), #"abc")
