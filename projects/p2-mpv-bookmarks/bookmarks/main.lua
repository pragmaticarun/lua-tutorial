-- bookmarks: an mpv script directory (bookmarks/main.lua). mpv adds the
-- directory to package.path, so require("store") finds store.lua next to it.
--
-- Bindings (rebind in input.conf with "KEY script-binding bookmarks/NAME"):
--   Ctrl+b add   Ctrl+d delete   Ctrl+n next   Ctrl+p previous
--   Ctrl+l list on the OSD       Ctrl+e export as chapters
-- Script messages: "bookmarks-add [title]" adds one from another script or
-- from input.conf. After every action it broadcasts
-- "bookmarks-done ACTION COUNT", so other scripts (and our tests) can follow.
local mp = require("mp")
local utils = require("mp.utils")
local options = require("mp.options")
local Store = require("store")

local opts = { dir = "~~/bookmarks", osd_seconds = 3 }   -- ~~ = mpv's config dir
options.read_options(opts, "bookmarks")

local store = Store.new()
local file          -- where this media's bookmarks live

local function say(fmt, ...)
  local text = fmt:format(...)
  print(text)                                   -- the log: "[bookmarks] ..."
  mp.osd_message(text, opts.osd_seconds)
end

local function media_file()
  -- one file per media, named after the media's file name (made safe)
  local path = mp.get_property("path", "unknown")
  local _, name = utils.split_path(path)
  local dir = mp.command_native({ "expand-path", opts.dir })
  return utils.join_path(dir, (name:gsub("[^%w%.%-_]", "_")) .. ".bookmarks")
end

local function save()
  local dir = mp.command_native({ "expand-path", opts.dir })
  if not utils.file_info(dir) then
    mp.command_native({ name = "subprocess", args = { "mkdir", "-p", dir }, playback_only = false })
  end
  local f = io.open(file, "w")
  if not f then say("cannot write %s", file) return end
  f:write(store:serialize())
  f:close()
end

local function done(action)
  mp.commandv("script-message", "bookmarks-done", action, tostring(store:count()))
end

local function now() return mp.get_property_number("time-pos", 0) end

local function add(title)
  local b, new = store:add(now(), title)
  save()
  say("%s bookmark %s at %s", new and "added" or "moved", b.title, Store.format_time(b.time))
end

local function jump(b, what)
  if not b then say("no %s bookmark", what) return end
  mp.commandv("seek", tostring(b.time), "absolute+exact")
  say("%s: %s (%s)", what, b.title, Store.format_time(b.time))
end

mp.add_key_binding("ctrl+b", "add", function() add() done("add") end)
mp.add_key_binding("ctrl+d", "delete", function()
  local b = store:remove_near(now())
  if b then save() say("deleted %s", b.title) else say("no bookmarks") end
  done("delete")
end)
mp.add_key_binding("ctrl+n", "next", function() jump(store:next_after(now()), "next") done("next") end)
mp.add_key_binding("ctrl+p", "previous", function()
  jump(store:prev_before(now()), "previous") done("previous")
end)
mp.add_key_binding("ctrl+l", "list", function()
  local lines = store:lines(now())
  say("%d bookmarks%s%s", #lines, #lines > 0 and "\n" or "", table.concat(lines, "\n"))
  done("list")
end)
mp.add_key_binding("ctrl+e", "export", function()
  -- chapter-list is writable: the bookmarks become real chapters, so mpv's
  -- own chapter keys (PgUp/PgDn) and the OSC's chapter marks use them
  mp.set_property_native("chapter-list", store:to_chapters())
  say("exported %d bookmarks as chapters", store:count())
  done("export")
end)

mp.register_script_message("bookmarks-add", function(title) add(title) done("add") end)

mp.register_event("file-loaded", function()
  file = media_file()
  local f = io.open(file, "r")
  store = f and Store.parse(f:read("*a")) or Store.new()
  if f then f:close() end
  print(("loaded %d bookmarks for %s"):format(store:count(), mp.get_property("filename")))
  done("load")
end)
