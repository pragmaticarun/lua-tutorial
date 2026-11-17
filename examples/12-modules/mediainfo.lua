-- module
-- mediainfo.lua: a module is a file that returns a table
local M = {}                               -- the public interface

local LOADS = 0                            -- private: invisible to users
print("[mediainfo] loading module")        -- runs once, on the first require

local function pad(n) return string.format("%02d", n) end   -- private helper

function M.timecode(seconds)
  local h = math.floor(seconds / 3600)
  local m = math.floor(seconds / 60) % 60
  local s = math.floor(seconds % 60)
  return pad(h) .. ":" .. pad(m) .. ":" .. pad(s)
end

function M.aspect(w, h)
  local function gcd(a, b) if b == 0 then return a end return gcd(b, a % b) end
  local g = gcd(w, h)
  return math.floor(w / g) .. ":" .. math.floor(h / g)
end

M.VERSION = "1.0"
return M
