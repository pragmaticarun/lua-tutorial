-- host: love
-- conf.lua runs before the modules load: window settings and which
-- love.* modules to enable. Unused modules cost startup time (and audio
-- needs a sound device, which a CI machine does not have).
function love.conf(t)
  t.identity = "lesson24-collector"
  t.version = "11.5"                 -- the LÖVE version this game targets
  t.window.title = "Collector"
  t.window.width, t.window.height = 320, 240
  t.window.vsync = 0                 -- no waiting for the monitor in tests
  t.modules.audio = false
  t.modules.sound = false
  t.modules.joystick = false
  t.modules.physics = false          -- we do our own collisions
end
