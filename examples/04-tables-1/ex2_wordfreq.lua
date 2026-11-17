-- Exercise 2 solution: word frequencies, most common first
local text = "the quick fox jumps over the lazy dog the fox"
local freq = {}
for word in text:gmatch("%a+") do
  freq[word] = (freq[word] or 0) + 1
end
local words = {}
for w in pairs(freq) do words[#words + 1] = w end
table.sort(words, function(a, b)
  if freq[a] ~= freq[b] then return freq[a] > freq[b] end
  return a < b                       -- tie-break so output is deterministic
end)
for i = 1, 3 do print(words[i], freq[words[i]]) end
