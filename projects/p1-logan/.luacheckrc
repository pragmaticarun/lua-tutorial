-- luacheck settings for the project (Lesson 28)
std = "max"                     -- globals of Lua 5.1-5.4 and LuaJIT
max_line_length = 130
files["spec/"] = { std = "+busted" }
files["*.rockspec"] = { std = "+rockspec" }
