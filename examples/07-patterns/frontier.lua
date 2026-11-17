-- frontier.lua: %f[set] matches the transition into 'set' (a word boundary)
local s = "the cat concatenated cats"
print((s:gsub("cat", "dog")))                    -- replaces inside words too
print((s:gsub("%f[%a]cat%f[%A]", "dog")))        -- whole word "cat" only
