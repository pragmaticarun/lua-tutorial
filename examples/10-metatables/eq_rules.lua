-- eq_rules.lua: when is __eq called?
local yes = setmetatable({}, { __eq = function() return true end })
local no = setmetatable({}, { __eq = function() return false end })
print(yes == {})          -- only one operand has __eq
print(yes == no)          -- different __eq functions: whose wins?
print(yes == yes, rawequal(yes, {}))
