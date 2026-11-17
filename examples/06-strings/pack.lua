-- targets: 5.5, 5.4
-- pack.lua: string.pack / string.unpack (Lua 5.3+) read and write binary formats
-- build a minimal 44-byte WAV (RIFF) header, little-endian ("<")
local rate, channels, bits = 48000, 2, 16
local byte_rate = rate * channels * bits // 8
local header = string.pack("<c4I4c4c4I4I2I2I4I4I2I2c4I4",
  "RIFF", 36, "WAVE", "fmt ", 16, 1, channels, rate, byte_rate,
  channels * bits // 8, bits, "data", 0)
print("header bytes:", #header)

-- parse it back
local riff, size, wave, fmt, fmtlen, format, ch, sr, br, align, bps =
  string.unpack("<c4I4c4c4I4I2I2I4I4I2I2", header)
print(riff, wave, fmt, "format=" .. format, "channels=" .. ch,
      "rate=" .. sr, "bits=" .. bps, "byterate=" .. br)
