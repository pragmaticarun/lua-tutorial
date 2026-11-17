-- Exercise 4 solution: SRT subtitle timestamps to milliseconds
local function to_ms(h, m, s, ms)
  return ((tonumber(h) * 60 + tonumber(m)) * 60 + tonumber(s)) * 1000 + tonumber(ms)
end
local line = "00:01:02,345 --> 00:01:04,000"
local pat = "(%d+):(%d+):(%d+),(%d+)"
local a1, a2, a3, a4, b1, b2, b3, b4 = line:match(pat .. " %-%-> " .. pat)
local start, stop = to_ms(a1, a2, a3, a4), to_ms(b1, b2, b3, b4)
print(start, stop, "duration " .. (stop - start) .. " ms")
