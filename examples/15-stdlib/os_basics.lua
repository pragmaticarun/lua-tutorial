-- os_basics.lua: time, dates, environment, processes
local t = 1794386141                            -- a fixed instant (Unix seconds)
print(os.date("!%Y-%m-%d %H:%M:%S", t))         -- '!' = UTC; without it: local time
local d = os.date("!*t", t)                     -- a table of fields
print(d.year, d.month, d.day, d.hour, d.wday, d.yday)
print(os.date("!%A %d %B %Y", t))
print(type(os.time()), type(os.clock()))        -- now (seconds), CPU time (seconds)
print(os.difftime(t + 90, t))                   -- difference in seconds (a float)
print(os.getenv("LUA_TUTORIAL_SURELY_UNSET"))   -- nil when not set
local p = io.popen("echo hello from the shell")
print(p:read("l"))
p:close()
