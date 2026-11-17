-- searchpath.lua: how require finds files
package.path = "./?.lua;./?/init.lua"          -- templates; '?' = name with dots -> '/'
package.cpath = "./?.so"                       -- C modules: keep the demo self-contained
print(package.searchpath("mediainfo.codecs", package.path))
print(package.searchpath("nope", package.path))
print("directory separator:", package.config:sub(1, 1))
print(pcall(require, "nope"))
