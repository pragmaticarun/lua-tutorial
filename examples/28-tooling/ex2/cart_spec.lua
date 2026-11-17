-- host: busted
-- Exercise 2: test code that talks to a payment gateway, without one:
-- stub the gateway, spy on the logger, and use before_each for fresh state.
local function new_cart(gateway, log)
  local items = {}
  return {
    add = function(name, price) items[#items + 1] = { name = name, price = price } end,
    total = function()
      local t = 0
      for _, it in ipairs(items) do t = t + it.price end
      return t
    end,
    checkout = function(self)
      local ok, err = gateway.charge(self.total())
      log(ok and "charged" or ("failed: " .. err))
      return ok
    end,
  }
end

describe("cart", function()
  local gateway, log, cart

  before_each(function()
    gateway = { charge = function() error("real gateway called in a test!") end }
    log = spy.new(function() end)
    cart = new_cart(gateway, log)
    cart.add("book", 12)
    cart.add("pen", 3)
  end)

  it("charges the total", function()
    stub(gateway, "charge").returns(true)
    assert.is_true(cart:checkout())
    assert.stub(gateway.charge).was.called_with(15)
    assert.spy(log).was.called_with("charged")
  end)

  it("reports a declined card", function()
    stub(gateway, "charge").returns(false, "declined")
    assert.is_false(cart:checkout())
    assert.spy(log).was.called_with("failed: declined")
  end)

  it("starts every test with a fresh cart", function()
    assert.are.equal(15, cart.total())
    assert.spy(log).was_not.called()
  end)
end)
