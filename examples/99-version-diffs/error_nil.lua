-- error_nil.lua: raising nil as an error object
print(pcall(error, nil))
print(pcall(error, { code = 42 }) == false)   -- tables are fine everywhere
