-- defaults.lua: __index as a table supplies fallback values
local defaults = { codec = "h264", crf = 23, preset = "medium" }
local job = setmetatable({ crf = 18 }, { __index = defaults })

print(job.codec, job.crf, job.preset)     -- missing keys are looked up in defaults
print(rawget(job, "codec"))               -- rawget bypasses metamethods: nil
print(getmetatable(job).__index == defaults)
job.codec = "av1"                         -- assignment goes to job itself
print(job.codec, defaults.codec)
