-- Exercise 4 solution: a classic hex dump, 8 bytes per row
local function hexdump(data)
  for offset = 1, #data, 8 do
    local chunk = data:sub(offset, offset + 7)
    local hex = chunk:gsub(".", function(c) return string.format("%02x ", c:byte()) end)
    local ascii = chunk:gsub("[^%g ]", ".")   -- %g = printable except space
    print(string.format("%04x  %-24s |%s|", offset - 1, hex, ascii))
  end
end
hexdump("RIFF\36\0\0\0WAVEfmt \16\0\0\0")
