-- Exercise 1 test: the strutil C module
local su = require("ex1_strutil")
print("[" .. su.trim("  \t video.mp4 \n") .. "]", #su.trim("a\0b "))
print(su.startswith("video.mp4", "video"), su.startswith("vid", "video"))
print(su.count("a,b,,c", ","), pcall(su.count, "abc", "ab"))
