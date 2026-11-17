-- host: luarocks
-- A rockspec is plain Lua assigning globals. The file name must be
-- <package>-<version>-<revision>.rockspec and match the fields below.
rockspec_format = "3.0"
package = "textkit"
version = "0.1.0-1"
source = {
  url = "git+https://github.com/pragmaticarun/lua-tutorial.git",
  tag = "v0.1.0",
}
description = {
  summary = "Small text helpers (trim, slugify, split, wrap)",
  detailed = "The example package from Lesson 28 of the Lua tutorial.",
  homepage = "https://pragmaticarun.github.io/lua-tutorial/",
  license = "MIT",
}
dependencies = {
  "lua >= 5.1, < 5.6",
}
test_dependencies = {
  "busted >= 2.0",
}
build = {
  type = "builtin",
  modules = {
    ["textkit"] = "src/textkit/init.lua",
    ["textkit.wrap"] = "src/textkit/wrap.lua",
  },
}
test = {
  type = "busted",
}
