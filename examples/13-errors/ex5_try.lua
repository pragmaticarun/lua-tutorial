-- Exercise 5 solution: try { } catch { } finally { } built on xpcall
local function try(block)
  local ok, err = xpcall(block[1], function(e)
    return { err = e, trace = debug.traceback("", 2) }
  end)
  if not ok and block.catch then block.catch(err.err, err.trace) end
  if block.finally then block.finally() end
  return ok
end
try {
  function() print("decoding"); error({ code = 42 }) end,
  catch = function(e, trace)
    print("caught code", e.code, "trace has frames:", trace:find("stack traceback") ~= nil)
  end,
  finally = function() print("cleanup") end,
}
print(try { function() print("all good") end, finally = function() print("cleanup 2") end })
