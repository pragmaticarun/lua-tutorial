-- memory: allocates without bound. The allocator refuses to go past the
-- state's budget, Lua raises "not enough memory", the host reports it.
function process(frame)
  local t = {}
  for i = 1, 1e7 do t[i] = ("x"):rep(64) .. i end
end
