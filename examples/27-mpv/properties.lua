-- host: mpv
-- Properties: mpv's state, readable, writable and observable by name.
-- The file is opened paused (--pause), so nothing moves while we look.
local log = print

mp.register_event("file-loaded", function()
  -- typed getters: string, number, boolean, native (Lua tables)
  log("filename:", mp.get_property("filename"))
  log("width x height:", mp.get_property_number("width"), mp.get_property_number("height"))
  log("container-fps:", mp.get_property_number("container-fps"))
  log("paused:", mp.get_property_bool("pause"))
  local tracks = mp.get_property_native("track-list")
  for _, t in ipairs(tracks) do
    log(("track %d: type=%s codec=%s %sx%s"):format(t.id, t.type, t.codec,
      tostring(t["demux-w"]), tostring(t["demux-h"])))
  end
  -- sub-properties and counts via the "/" syntax
  log("track-list/count:", mp.get_property_number("track-list/count"))
  -- a missing property returns nil plus an error message
  log("missing:", mp.get_property("no-such-property"))
  -- the OSD form is formatted for humans
  log("speed (osd form):", mp.get_property_osd("speed"))

  -- observing: the callback runs once now, then on every change
  mp.observe_property("speed", "number", function(name, value)
    log("observed", name, "=", value)
  end)
  mp.observe_property("volume", "number", function(name, value)
    log("observed", name, "=", value)
  end)

  -- property expansion, the same syntax as in input.conf / --term-status-msg
  log("expand-text:", mp.command_native({ "expand-text", "${width}x${height} @ ${speed}x" }))

  -- setting: set_property_* or commands; changes are delivered asynchronously
  mp.add_timeout(0.05, function()
    mp.set_property_number("speed", 1.5)
    mp.command("add volume -10")
    mp.command("multiply speed 2")
    mp.add_timeout(0.1, function()
      log("final speed:", mp.get_property_number("speed"),
          "volume:", mp.get_property_number("volume"))
      local ok, err = mp.set_property("speed", "fast")      -- invalid value
      log("set_property('speed', 'fast'):", ok, err)
      mp.command("quit")
    end)
  end)
end)
