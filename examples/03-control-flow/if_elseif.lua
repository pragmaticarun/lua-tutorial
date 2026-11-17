-- if_elseif.lua: if / elseif / else, and conditions are any value
local function classify(bitrate_kbps)
  if bitrate_kbps == nil then
    return "unknown"
  elseif bitrate_kbps < 128 then
    return "low"
  elseif bitrate_kbps < 320 then
    return "medium"
  else
    return "high"
  end
end
for _, b in ipairs({ 96, 192, 320 }) do
  print(b, classify(b))
end
print("nil", classify(nil))
