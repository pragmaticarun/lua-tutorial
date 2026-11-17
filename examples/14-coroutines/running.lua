-- running.lua: coroutine introspection across versions
local co, is_main = coroutine.running()
print("main thread:", type(co), is_main)
print("isyieldable in main:", coroutine.isyieldable())
print(coroutine.wrap(function() return coroutine.isyieldable() end)())
print("coroutine.close available:", coroutine.close ~= nil)
