-- Exercise 1 solution: collect #hashtags (letters, digits, underscore)
local post = "Shipping #Lua5_5 support for #mpv scripts! #100DaysOfCode #"
local tags = {}
for tag in post:gmatch("#([%w_]+)") do tags[#tags + 1] = tag end
print(#tags, table.concat(tags, ", "))
