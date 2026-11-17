-- targets: jit
-- trace_events.lua: count trace starts, stops and aborts with jit.attach
local vmdef = require("jit.vmdef")     -- names of bytecodes and trace errors

local function watch(label, fn)
  local counts, reasons = { start = 0, stop = 0, abort = 0 }, {}
  local function handler(what, _, _, _, err, info)
    counts[what] = (counts[what] or 0) + 1
    if what == "abort" then
      local msg = vmdef.traceerr[err] or tostring(err)
      if type(info) == "number" and msg:find("%%s") then  -- bytecode number -> name
        msg = msg:format(vmdef.bcnames:sub(info * 6 + 1, info * 6 + 6):gsub("%s+$", ""))
      end
      reasons[msg] = true
    end
  end
  jit.attach(handler, "trace")
  fn()
  jit.attach(handler)                    -- detach: same function, no event name
  local why = {}
  for k in pairs(reasons) do why[#why + 1] = k end
  table.sort(why)
  print(("%-22s start=%d stop=%d abort=%d"):format(label, counts.start, counts.stop,
    counts.abort) .. (#why > 0 and "  (" .. table.concat(why, "; ") .. ")" or ""))
end

watch("closure per iteration", function()
  local fs = {}
  for i = 1, 1000 do fs[i] = function() return i end end
end)

local function get(i) return i end
watch("hoisted function", function()
  local fs = {}
  for i = 1, 1000 do fs[i] = get(i) end
end)
