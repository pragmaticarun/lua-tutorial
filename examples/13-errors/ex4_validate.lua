-- Exercise 4 solution: collect all validation errors instead of stopping at one
local function validate(cfg)
  local errors = {}
  local function check(cond, msg) if not cond then errors[#errors + 1] = msg end end
  check(type(cfg.input) == "string", "input: required string")
  check(type(cfg.fps) == "number" and cfg.fps > 0, "fps: must be a positive number")
  check(cfg.codec == nil or ({ h264 = 1, hevc = 1, av1 = 1 })[cfg.codec], "codec: unsupported")
  if #errors > 0 then return nil, errors end
  return true
end
local ok, errs = validate({ fps = -1, codec = "mpeg1" })
print(ok)
for _, e in ipairs(errs) do print("  " .. e) end
print(validate({ input = "a.mov", fps = 30 }))
