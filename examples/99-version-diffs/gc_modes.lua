-- gc_modes.lua: collector modes and parameters
print("generational:", pcall(collectgarbage, "generational"))
print("incremental: ", pcall(collectgarbage, "incremental"))
print("param:       ", (pcall(collectgarbage, "param", "pause")))
