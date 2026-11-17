-- dicts.lua: the same table type is also a hash map
local stream = { codec = "av1", width = 1920, height = 1080 }
print(stream.codec, stream["width"])      -- t.name is sugar for t["name"]

stream.fps = 60                           -- add a field
stream.height = nil                       -- delete a field: assign nil
print(stream.fps, stream.height)

-- any value except nil (and NaN) can be a key
local seen = {}
local key_table, key_fn = {}, print
seen[key_table] = "a table key"
seen[key_fn] = "a function key"
seen[true] = "a boolean key"
print(seen[key_table], seen[print], seen[true])

-- number keys are normalised: 1 and 1.0 are the same key, "1" is different
local t = {}
t[1] = "integer one"; t["1"] = "string one"
print(t[1.0], t["1"])

-- counting entries in a map needs a loop: # is only for sequences
local n = 0
for _ in pairs(stream) do n = n + 1 end
print("fields:", n)
