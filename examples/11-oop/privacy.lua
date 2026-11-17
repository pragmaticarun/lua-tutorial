-- privacy.lua: objects as closures - truly private state, no self
local function new_account(owner, balance)
  balance = balance or 0                          -- private: only closures see it
  local self = {}
  function self.deposit(v)
    assert(v > 0, "deposit must be positive")
    balance = balance + v
  end
  function self.withdraw(v)
    if v > balance then return nil, "insufficient funds" end
    balance = balance - v
    return balance
  end
  function self.balance() return balance end
  function self.owner() return owner end
  return self
end

local acc = new_account("arun", 100)
acc.deposit(50)                                   -- '.' not ':' - no self needed
print(acc.owner(), acc.balance())
print(acc.withdraw(500))
print(acc.withdraw(30))
print(type(acc.balance), acc.balance_value)       -- only the accessor is visible
