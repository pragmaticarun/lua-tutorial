local report = require("logan.report")

describe("logan.report", function()
  local st
  before_each(function()
    st = report.new()
    for i, s in ipairs({ 200, 200, 404, 500, 200 }) do
      report.add(st, { kind = "access", ip = "10.0.0." .. (i % 2), path = "/p" .. (i % 3),
                       status = s, bytes = 100, minute = "m" }, "t:" .. i)
    end
    report.add(st, nil, "t:6")
  end)

  it("counts lines, statuses and errors", function()
    assert.equal(6, st.lines)
    assert.equal(5, st.parsed)
    assert.equal(1, st.errors)
    assert.same({ "t:6" }, st.bad)
    assert.equal(3, st.class["2xx"])
  end)

  it("sorts top lists by count, then by key", function()
    local top = report.top(st.paths, 2)
    assert.same({ { key = "/p1", count = 2 }, { key = "/p2", count = 2 } }, top)
  end)

  it("encodes JSON with sorted keys and escapes", function()
    assert.equal('{"a":[1,2],"b":"x\\"y\\n"}', report.encode({ b = 'x"y\n', a = { 1, 2 } }))
    assert.equal("[]", report.encode({}))
  end)
end)
