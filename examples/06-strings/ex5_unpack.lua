-- targets: 5.5, 5.4
-- Exercise 5 solution: parse a big-endian chunk table with string.unpack
-- each chunk: 4-char tag, 32-bit big-endian length, then that many bytes
local data = string.pack(">c4I4", "ftyp", 4) .. "isom"
          .. string.pack(">c4I4", "mdat", 3) .. "\1\2\3"
local pos = 1
while pos <= #data do
  local tag, len
  tag, len, pos = string.unpack(">c4I4", data, pos)   -- returns next position too
  print(tag, len, (data:sub(pos, pos + len - 1):gsub("%c", "?")))
  pos = pos + len
end
