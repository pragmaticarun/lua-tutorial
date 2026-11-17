-- targets: 5.5
-- prealloc.lua: Lua 5.5 table.create(narray, nhash) preallocates storage
local samples = table.create(48000)         -- room for 48 000 array slots
print(#samples)                             -- still empty: only capacity is reserved
for i = 1, 48000 do samples[i] = 0 end      -- no rehashing while filling
print(#samples)
local meta = table.create(0, 4)             -- 4 hash slots for a small record
meta.codec, meta.rate, meta.channels, meta.bits = "pcm", 48000, 2, 16
print(meta.codec, meta.rate)
