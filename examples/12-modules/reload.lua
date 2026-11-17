-- reload.lua: forcing a module to load again (development hot-reload)
package.path = "./?.lua;" .. package.path
local a = require("mediainfo")
package.loaded["mediainfo"] = nil              -- forget the cached copy
local b = require("mediainfo")                 -- runs the file again
print(a == b, a.timecode(61), b.timecode(61))
