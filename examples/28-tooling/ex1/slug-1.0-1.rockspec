-- host: luarocks
-- Exercise 1: a rockspec for a single-file module, installable offline.
rockspec_format = "3.0"
package = "slug"
version = "1.0-1"
source = { url = "git+https://example.com/slug.git", tag = "v1.0" }
description = {
  summary = "Turn titles into URL slugs",
  license = "MIT",
}
dependencies = { "lua >= 5.1" }
build = {
  type = "builtin",
  modules = { slug = "slug.lua" },   -- module name = file path
}
