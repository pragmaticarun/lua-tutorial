-- The package description LuaRocks builds from (Lesson 28). "builtin" needs
-- no Makefile: it copies each module and installs bin/logan as a command.
rockspec_format = "3.0"
package = "logan"
version = "1.0.0-1"
source = {
  url = "git+https://github.com/pragmaticarun/lua-tutorial.git",
  tag = "logan-1.0.0",
  dir = "lua-tutorial/projects/p1-logan",
}
description = {
  summary = "A command-line log analyzer (access and application logs)",
  detailed = "Project 1 of the Lua tutorial: argument parsing, Lua patterns, reports.",
  homepage = "https://pragmaticarun.github.io/lua-tutorial/projects/p1-log-analyzer/",
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
    ["logan"] = "src/logan/init.lua",
    ["logan.args"] = "src/logan/args.lua",
    ["logan.parse"] = "src/logan/parse.lua",
    ["logan.report"] = "src/logan/report.lua",
  },
  install = {
    bin = { logan = "bin/logan" },
  },
}
test = {
  type = "busted",
}
