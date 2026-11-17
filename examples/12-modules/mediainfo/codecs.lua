-- module
-- mediainfo/codecs.lua: required as "mediainfo.codecs" (dots map to directories)
local codecs = {
  h264 = { kind = "video", year = 2003 },
  hevc = { kind = "video", year = 2013 },
  av1  = { kind = "video", year = 2018 },
  opus = { kind = "audio", year = 2012 },
}
return {
  info = function(name) return codecs[name] end,
  newer_than = function(year)
    local out = {}
    for name, c in pairs(codecs) do if c.year > year then out[#out + 1] = name end end
    table.sort(out)
    return out
  end,
}
