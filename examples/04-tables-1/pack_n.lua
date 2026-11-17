-- pack_n.lua: carry an explicit count when nils are legal values
local function pack(...)                    -- table.pack does this in 5.2+
  return { n = select("#", ...), ... }
end
local args = pack("a", nil, "c", nil)
print("n =", args.n)
for i = 1, args.n do print(i, args[i]) end
