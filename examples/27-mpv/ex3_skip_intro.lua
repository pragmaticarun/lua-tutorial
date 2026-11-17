-- host: mpv
-- Exercise 3: skip a chapter called "Intro". The test file has no
-- chapters, so we create some: chapter-list is a writable property.
mp.register_event("file-loaded", function()
  if mp.get_property_number("chapter-list/count", 0) == 0 then
    mp.set_property_native("chapter-list", {
      { title = "Intro", time = 0 },
      { title = "Main", time = 1.6 },
      { title = "Credits", time = 4 },
    })
  end
  local chapters = mp.get_property_native("chapter-list")
  for i, c in ipairs(chapters) do
    if c.title:lower() == "intro" and chapters[i + 1] then
      print(("skipping intro: %.2f -> %.2f"):format(c.time, chapters[i + 1].time))
      -- setting "chapter" (0-based) seeks to that chapter's start; mpv decides
      -- which chapter a frame time falls in, so no float boundary to worry about
      mp.set_property_number("chapter", i)
      return
    end
  end
end)

mp.register_event("playback-restart", function()
  local pos = mp.get_property_number("time-pos")
  if pos > 0 then
    local ch = mp.get_property_number("chapter")          -- 0-based
    print(("now at %.2f, chapter %d of %d: %s"):format(pos, ch + 1,
      mp.get_property_number("chapter-list/count"), mp.get_property("chapter-list/" .. ch .. "/title")))
    mp.command("quit")
  end
end)
