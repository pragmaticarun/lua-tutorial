-- io_files.lua: writing, reading and seeking files
local path = os.tmpname()                       -- a fresh temporary file name

local f = assert(io.open(path, "w"))            -- modes: r w a r+ w+ a+ (add b for binary)
f:write("frame,pts,size\n", "1,0,4210\n", "2,40,1187\n", "3,80,1302\n")
f:close()

for line in io.lines(path) do io.write("[", line, "] ") end   -- closes when done
print()

f = assert(io.open(path, "r"))
print(f:read("l"))                              -- one line, without the newline
print(f:read("n", "n"))                         -- numbers: 1 then ",0" fails -> nil
f:seek("set", 0)                                -- rewind
local all = f:read("a")                         -- the whole rest of the file
print(#all, select(2, all:gsub("\n", "")) .. " lines")
print(f:seek("end"))                            -- seek returns the new position
f:close()

f = assert(io.open(path, "a")); f:write("4,120,999\n"); f:close()
local n = 0
for _ in io.lines(path) do n = n + 1 end
print("after append:", n, "lines")
print(os.remove(path))                          -- true on success
print(select("#", io.open(path)), (select(3, io.open(path))))  -- nil, message, errno
