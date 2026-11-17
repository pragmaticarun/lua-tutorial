-- host: mpv
-- On-screen display: osd_message for quick text, overlays with ASS markup
-- for anything richer. With --vo=null nothing is drawn (osd-width is 0),
-- but mpv still lays overlays out, so we can check where they would go.
local log = print
local assdraw = require("mp.assdraw")

mp.register_event("file-loaded", function()
  -- 1. osd_message: the same as the show-text command (here: invisible)
  mp.osd_message("Hello from Lua", 2)
  log("osd size with --vo=null:", mp.get_property_number("osd-width"), mp.get_property_number("osd-height"))

  -- 2. a text overlay with ASS tags. res_x/res_y define the coordinate space.
  local title = mp.create_osd_overlay("ass-events")
  title.res_x, title.res_y = 640, 360
  title.data = "{\\an7\\pos(20,20)\\fs30\\b1\\c&H00FFFF&}Chapter 1"   -- colours are BGR
  title:update()
  log("title:", title.data)

  -- 3. vector drawing with mp.assdraw: a progress bar at 25 %
  local function bar(fraction)
    local a = assdraw.ass_new()
    a:new_event()
    a:append("{\\an7\\bord0\\shad0\\1c&H404040&}")
    a:pos(20, 300)
    a:draw_start(); a:rect_cw(0, 0, 600, 20); a:draw_stop()   -- background
    a:new_event()
    a:append("{\\an7\\bord0\\shad0\\1c&HFFFFFF&}")
    a:pos(20, 300)
    a:draw_start(); a:rect_cw(0, 0, 600 * fraction, 20); a:draw_stop()
    return a.text
  end
  local ov = mp.create_osd_overlay("ass-events")
  ov.res_x, ov.res_y = 640, 360
  ov.data = bar(0.25)
  ov.compute_bounds = true          -- ask mpv/libass where it ended up
  local r = ov:update()
  log(("bar bounds: %d,%d - %d,%d"):format(r.x0, r.y0, r.x1, r.y1))
  for line in ov.data:gmatch("[^\n]+") do log("  " .. line) end

  ov:remove(); title:remove()
  mp.command("quit")
end)
