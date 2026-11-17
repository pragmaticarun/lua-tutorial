-- conf.lua: read by LÖVE before anything else.
function love.conf(t)
  t.identity = "brick-rush"            -- save directory name (high scores live there)
  t.version = "11.5"
  t.window.title = "Brick Rush"
  t.window.width, t.window.height = 640, 480   -- the 320x240 game, scaled x2
  t.window.vsync = 1
  t.modules.audio = false              -- no sound in this version (see the exercises)
  t.modules.sound = false
  t.modules.joystick = false
  t.modules.physics = false            -- we do our own collisions
end
