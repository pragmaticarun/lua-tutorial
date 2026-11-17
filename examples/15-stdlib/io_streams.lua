-- stdin: io_streams.input
-- io_streams.lua: stdin/stdout, io.read formats and io.write chaining
local count = io.read("n")                      -- a number
io.read("l")                                    -- consume the rest of that line
local values = {}
for i = 1, count do values[i] = io.read("n") end
io.read("l")
local title = io.read("l")
local rest = io.read("a")                       -- everything left
io.write("count=", count, " sum=", values[1] + values[2] + values[3], "\n")
io.write("title=", title, "\n")
io.write("rest has ", #rest, " bytes\n")
print(io.type(io.stdout), io.type(42))          -- "file", "closed file" or nil
