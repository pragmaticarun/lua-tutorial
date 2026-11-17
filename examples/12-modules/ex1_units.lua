-- Exercise 1 solution: use a module with a private helper
package.path = "./ex/?.lua;" .. package.path
local units = require("units")
print(units.bytes(512), units.bytes(1536), units.bytes(734003200))
print(units.bitrate(4987000), units.scale, units.SUFFIXES)
