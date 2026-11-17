-- named_args.lua: emulate named / optional arguments with a table
local function encode(opts)
  local codec = opts.codec or "h264"
  local crf = opts.crf or 23
  local preset = opts.preset or "medium"
  assert(opts.input, "input is required")
  return string.format("ffmpeg -i %s -c:v %s -crf %d -preset %s",
                       opts.input, codec, crf, preset)
end
print(encode { input = "in.mov" })
print(encode { input = "in.mov", codec = "libx265", crf = 28 })
print(pcall(encode, { codec = "av1" }))
