-- host: busted
local wrap = require("textkit.wrap").wrap

describe("wrap", function()
  it("wraps greedily at the width", function()
    assert.are.same({ "the quick", "brown fox" }, wrap("the quick brown fox", 10))
  end)

  it("keeps long words whole", function()
    assert.are.same({ "a", "extraordinarily", "b" }, wrap("a extraordinarily b", 5))
  end)

  it("validates the width", function()
    assert.has_error(function()
      wrap("x", 0)
    end)
  end)

  -- spies record calls; stubs replace functions for the duration of a test
  it("can be observed with a spy", function()
    local s = spy.new(wrap)
    s("one two", 3)
    assert.spy(s).was.called(1)
    assert.spy(s).was.called_with("one two", 3)
  end)
end)
