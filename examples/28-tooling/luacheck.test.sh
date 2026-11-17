# host: luacheck
echo "--- the textkit project is clean"
(cd textkit && luacheck --no-color .) | tail -1
echo "--- the messy file is not"
luacheck --no-color --codes --formatter plain bad/messy.lua
echo "exit status: $?"
