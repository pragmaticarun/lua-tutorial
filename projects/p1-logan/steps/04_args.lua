-- Step 4: the argument parser on its own: results and error messages.
package.path = "../src/?.lua;../src/?/init.lua;" .. package.path
local args = require("logan.args")
local logan = require("logan")

local function try(argv)
  local opts, files = args.parse(logan.spec, argv)
  io.write(("%-34s -> "):format(table.concat(argv, " ")))
  if not opts then print("error: " .. files) return end
  print(("top=%d format=%s output=%s status=%s files={%s}"):format(
    opts.top, opts.format, opts.output, tostring(opts.status), table.concat(files, ",")))
end

try({ "access.log" })
try({ "-n3", "--format=combined", "a.log", "b.log" })
try({ "--top", "10", "-s", "4xx,500", "-o", "json", "-" })
try({ "--", "-odd-name.log" })
try({ "-n" })
try({ "--top=lots" })
try({ "-o", "xml" })
try({ "--colour" })
print()
print(args.help(logan.spec))
