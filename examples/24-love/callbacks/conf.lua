-- host: love
-- No sound in this demo, so do not open an audio device: on a machine
-- without one (like a CI runner) OpenAL prints "Could not open device."
function love.conf(t)
  t.modules.audio = false
  t.modules.sound = false
end
