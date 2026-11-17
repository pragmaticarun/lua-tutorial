-- use_modules.lua: require, the module cache and submodules
package.path = "./?.lua;" .. package.path      -- look in the current directory first

local mi = require("mediainfo")                -- runs mediainfo.lua once
local again = require("mediainfo")             -- cached: no second "loading"
print(mi == again, package.loaded.mediainfo == mi)
print(mi.timecode(3725), mi.aspect(1920, 1080), mi.VERSION)
print(mi.pad, mi.LOADS)                        -- locals stay private

local codecs = require("mediainfo.codecs")     -- file mediainfo/codecs.lua
print(codecs.info("av1").year, table.concat(codecs.newer_than(2010), ","))
