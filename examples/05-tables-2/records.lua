-- records.lua: tables as structs, with nested records and mixed constructors
local clip = {
  title = "intro",
  duration = 12.5,
  video = { codec = "h264", width = 1280, height = 720 },
  tags = { "demo", "720p" },               -- an array inside a record
  ["frame-rate"] = 30,                      -- non-identifier key needs brackets
}
print(clip.title, clip.video.codec, clip.tags[2], clip["frame-rate"])

-- a constructor can mix positional and named entries; ';' also separates
local mixed = { "a", "b"; kind = "letters", "c", }
print(#mixed, mixed.kind, mixed[3])

-- a "constructor function" gives you defaults and a single place to validate
local function new_clip(t)
  assert(type(t.title) == "string", "title required")
  return { title = t.title, duration = t.duration or 0, tags = t.tags or {} }
end
local c = new_clip { title = "outro" }      -- f{...} calls f with one table
print(c.title, c.duration, #c.tags)
