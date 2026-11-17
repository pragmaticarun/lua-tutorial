-- backtrack: burns wall-clock time inside ONE C call. string.find with this
-- pattern tries every way to split 100 "a"s four times (millions of steps),
-- yet the script itself executes only a handful of Lua instructions, so the
-- instruction count hook never fires during the call.
local s = ("a"):rep(100)

function process(frame)
  local found = s:find(".-.-.-.-b")        -- never matches; takes ~0.6 s
  frame:set(0, 0, found and 255 or 0)
end
