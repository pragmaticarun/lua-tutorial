-- greedy.lua: * and + are greedy, - is lazy
local html = "<b>bold</b> and <i>italic</i>"
print(html:match("<(.*)>"))     -- greedy: as much as possible
print(html:match("<(.-)>"))     -- lazy: as little as possible
for tag in html:gmatch("<(%a+)>") do io.write(tag, " ") end
print()
