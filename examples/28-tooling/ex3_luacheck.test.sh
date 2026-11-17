# host: luacheck
cd ex3
echo "--- without the config"
luacheck --no-color --codes --formatter plain --no-config legacy.lua
echo "--- with ex3/.luacheckrc"
luacheck --no-color --codes legacy.lua | tail -1
