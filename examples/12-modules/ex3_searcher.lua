-- Exercise 3 solution: a custom searcher that loads modules from strings
-- (e.g. scripts embedded in a C++ binary). Works on 5.2+ and LuaJIT.
local sources = {
  greet = "local M = {} function M.hi(n) return 'hi ' .. n end return M",
  answer = "return 42",
}
local function string_searcher(name)
  local src = sources[name]
  if not src then return "\n\tno embedded source '" .. name .. "'" end
  local chunk, err = (loadstring or load)(src, "=embedded:" .. name)
  if not chunk then error(err) end
  return chunk
end
local searchers = package.searchers or package.loaders   -- 5.1/LuaJIT name
table.insert(searchers, 2, string_searcher)               -- after preload
print(require("greet").hi("arun"), (require("answer")))   -- () keeps one result
print(select(2, pcall(require, "missing")):match("no embedded source 'missing'"))
