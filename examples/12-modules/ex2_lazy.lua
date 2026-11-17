-- Exercise 2 solution: lazily require submodules on first access
package.path = "./?.lua;" .. package.path
local function lazy(prefix)
  return setmetatable({}, {
    __index = function(t, name)
      local mod = require(prefix .. "." .. name)   -- load on demand
      rawset(t, name, mod)                         -- cache in the proxy
      return mod
    end,
  })
end
local media = lazy("mediainfo")
print(package.loaded["mediainfo.codecs"] ~= nil)   -- not loaded yet
print(media.codecs.info("opus").kind)              -- first access loads it
print(package.loaded["mediainfo.codecs"] ~= nil)
