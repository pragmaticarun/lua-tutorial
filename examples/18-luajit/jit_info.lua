-- targets: jit
-- jit_info.lua: what the `jit` module tells you
print(jit.version)                  -- the 2.1 branch is "rolling": 2.1.<commit time>
print(jit.os, jit.arch)
local status = { jit.status() }     -- true/false, then CPU features and optimisations
print("JIT enabled:", status[1])
local flags = {}
for i = 2, #status do flags[status[i]] = true end
-- CPU feature flags (SSE4.1, BMI2, ...) depend on the machine; optimisation
-- passes do not:
local opts = {}
for _, opt in ipairs({ "fold", "cse", "dce", "fwd", "dse", "narrow", "loop", "abc", "sink", "fuse" }) do
  opts[#opts + 1] = opt .. (flags[opt] and "+" or "-")
end
print(table.concat(opts, " "))

jit.off()                           -- run everything in the interpreter...
print("after jit.off():", (jit.status()))
jit.on()                            -- ...and back on
print("after jit.on():", (jit.status()))
