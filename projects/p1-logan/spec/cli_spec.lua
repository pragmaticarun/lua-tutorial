local logan = require("logan")

-- a stand-in for io.stdout / io.stderr that remembers what was written
local function sink()
  local s = { text = "" }
  function s:write(...) self.text = self.text .. table.concat({ ... }) return self end
  return s
end

describe("logan.main", function()
  local out, err
  before_each(function() out, err = sink(), sink() end)

  it("prints help and exits 0", function()
    assert.equal(0, logan.main({ "--help" }, out, err))
    assert.truthy(out.text:find("usage: logan", 1, true))
  end)

  it("exits 2 with a hint on a usage error", function()
    assert.equal(2, logan.main({ "--bogus" }, out, err))
    assert.equal("logan: unknown option '--bogus'\ntry 'logan --help'\n", err.text)
  end)

  it("exits 1 when a file cannot be opened, but still reports the rest", function()
    assert.equal(1, logan.main({ "data/app.log", "missing.log" }, out, err))
    assert.truthy(err.text:find("missing.log", 1, true))
    assert.truthy(out.text:find("^lines: 24 "))
  end)

  it("filters by status class", function()
    assert.equal(0, logan.main({ "-s", "5xx", "-o", "json", "data/access.log" }, out, err))
    assert.truthy(out.text:find('"classes":{"5xx":11}', 1, true))
  end)

  it("reads standard input for '-'", function()
    local stdin = { lines = function() return ("2026-11-17T10:00:00Z ERROR [x] boom\n"):gmatch("[^\n]+") end }
    assert.equal(0, logan.main({ "-" }, out, err, stdin))
    assert.truthy(out.text:find("errors: 1", 1, true))
  end)
end)
