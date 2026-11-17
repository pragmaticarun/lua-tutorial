-- targets: 5.5, 5.4
-- use_buffer_close.lua: a C userdata with __close works with <close>
local buffer = require("buffer")
do
  local b <close> = buffer.new(16):fill(1)
  print(b:sum())
end                                          -- __close runs here
print(buffer.stats())
local ok, err = pcall(function()
  local b <close> = buffer.new(16)
  error("decoder failed")                    -- __close also runs on errors
end)
print(ok, err, buffer.stats())
