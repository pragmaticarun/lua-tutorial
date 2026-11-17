-- require_args.lua: arguments and extra results of require differ by version
package.path = "./?.lua;" .. package.path
local m, extra = require("args_module")
print("module chunk got " .. m.n .. " argument(s):", m.name, m.path)
print("require's second result:", extra)
print("searchers:", package.searchers ~= nil, "loaders:", package.loaders ~= nil)
