-- Input mapping driven by fake key events, the way the game test drives it.
package.path = "game/?.lua;" .. package.path
local Input = require("input")

local inp = Input.new({ left = { "left", "a" }, right = { "right", "d" }, jump = { "space" } })
local function frame(label)
  print(("%-22s axis=%2d jump down=%-5s pressed=%s"):format(label,
    inp:axis("left", "right"), tostring(inp:isDown("jump")), tostring(inp:wasPressed("jump"))))
  inp:endFrame()
end

frame("nothing")
inp:keypressed("d");      frame("d down")
inp:keypressed("left");   frame("d + left (cancel)")
inp:keyreleased("d");     frame("left only")
inp:keypressed("space");  frame("space pressed")
frame("space held")
inp:keypressed("a"); inp:keyreleased("left"); frame("a replaced left")
inp:keyreleased("space"); inp:keypressed("x"); frame("unbound key x")
