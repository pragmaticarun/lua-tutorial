-- host: mpv
-- Key bindings and script messages. In a real session you press the keys;
-- here the script "presses" them with the keypress / keydown / keyup commands.
local log = print

-- a simple binding: key, a name (for input.conf), and a function
mp.add_key_binding("b", "bookmark", function()
  log("bookmark at", mp.get_property("time-pos/full"))
end)

-- a binding with no default key: users bind it in input.conf as
--   Ctrl+x script-binding keybindings/speed-reset
mp.add_key_binding(nil, "speed-reset", function()
  mp.set_property_number("speed", 1)
  log("speed reset")
end)

-- complex bindings get down/up/repeat/press events
mp.add_key_binding("h", "hold", function(t)
  log("hold:", t.event, "key=" .. t.key_name)
end, { complex = true })

-- forced bindings win over the user's input.conf
mp.add_forced_key_binding("q", "no-quit", function() log("q is disabled by this script") end)

-- script messages: a tiny RPC between scripts, input.conf and the IPC socket
mp.register_script_message("greet", function(who, times)
  log(("greet %s x%s"):format(who, times))
end)

local steps = {
  "keypress b",
  "keydown h", "keyup h",
  "keypress q",                                  -- intercepted
  "script-binding keybindings/speed-reset",      -- same as pressing its key
  "script-message greet ann 2",                  -- broadcast to every script
  "script-message-to keybindings greet bo 1",    -- addressed to one script
}
mp.register_event("file-loaded", function()
  mp.set_property_number("speed", 2)
  for i, cmd in ipairs(steps) do
    -- commands are asynchronous: space them out so the log order is stable
    mp.add_timeout(0.05 * i, function() mp.command(cmd) end)
  end
  mp.add_timeout(0.05 * (#steps + 1), function()
    mp.remove_key_binding("no-quit")
    log("removed no-quit; speed is", mp.get_property_number("speed"))
    mp.command("keypress q")                     -- no longer reaches this script
    mp.add_timeout(0.05, function() mp.command("quit") end)
  end)
end)
