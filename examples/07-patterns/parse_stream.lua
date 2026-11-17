-- parse_stream.lua: pulling fields out of ffprobe-style text
local text = [[
  Stream #0:0(und): Video: h264 (High), yuv420p, 1920x1080, 4987 kb/s, 29.97 fps
  Stream #0:1(eng): Audio: aac (LC), 48000 Hz, stereo, fltp, 192 kb/s
  Stream #0:2(eng): Subtitle: mov_text
]]
for line in text:gmatch("[^\n]+") do
  local index, kind, codec = line:match("Stream #0:(%d+)%(%a+%): (%a+): ([%w_]+)")
  local info = { index = index, kind = kind, codec = codec }
  if kind == "Video" then
    info.w, info.h = line:match("(%d+)x(%d+)")
    info.fps = line:match("([%d%.]+) fps")
  elseif kind == "Audio" then
    info.rate = line:match("(%d+) Hz")
  end
  local fields = {}
  for _, k in ipairs({ "index", "kind", "codec", "w", "h", "fps", "rate" }) do
    if info[k] then fields[#fields + 1] = k .. "=" .. info[k] end
  end
  print(table.concat(fields, " "))
end
