-- os_execute.lua: exit statuses of child processes differ between versions
print(os.execute("exit 3"))
local p = io.popen("exit 2")
p:read("a")
print(p:close())
