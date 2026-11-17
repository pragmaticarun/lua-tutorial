-- host: busted
-- One passing and one failing test, to see busted's failure report.
local textkit = require("textkit")

describe("a failing suite", function()
  it("passes", function()
    assert.are.equal("a-b", textkit.slugify("A B"))
  end)

  it("fails", function()
    assert.are.same({ "a", "b" }, textkit.split("a,b,", ","))
  end)
end)
