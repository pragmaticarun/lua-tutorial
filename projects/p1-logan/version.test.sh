# interp: 5.5, 5.4, jit
# The one output that differs by interpreter (version.<id>.expected).
LUA_PATH="src/?.lua;src/?/init.lua;;" "$LUA" bin/logan --version
