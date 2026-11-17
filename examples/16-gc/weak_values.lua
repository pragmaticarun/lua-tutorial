-- weak_values.lua: a cache that does not keep its entries alive
local cache = setmetatable({}, { __mode = "v" })
local function load_texture(name)
  local tex = cache[name]
  if not tex then
    tex = { name = name }                -- pretend this is expensive
    cache[name] = tex
    print("loaded", name)
  end
  return tex
end

local a = load_texture("grass.png")
local b = load_texture("grass.png")      -- cache hit, no "loaded" line
print("same object:", a == b)

a, b = nil, nil                          -- nobody uses the texture any more
collectgarbage()
print("evicted:", cache["grass.png"] == nil)
load_texture("grass.png")                -- loaded again

-- Strings, numbers and booleans are values, not objects: never removed
local names = setmetatable({}, { __mode = "v" })
names[1] = "a string"; names[2] = 42; names[3] = {}
collectgarbage()
print(names[1], names[2], names[3])
