-- Exercise 1 solution: report interpreter facts
print("version:", _VERSION)
print("LuaJIT:", type(jit) == "table")
print("integer division operator:", (load("return 7 // 2")) ~= nil)
print("utf8 library:", type(utf8) == "table")
