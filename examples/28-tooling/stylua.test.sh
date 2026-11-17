# host: stylua
echo "--- textkit is formatted"
(cd textkit && stylua --check . && echo "stylua --check: OK")
echo "--- --check on the messy file prints a diff and fails"
cd textkit                                  # so textkit/.stylua.toml applies
stylua --color never --check ../bad/messy.lua
echo "exit status: $?"
echo "--- formatting from stdin (uses the .stylua.toml found from the cwd)"
stylua - < ../bad/messy.lua
echo "--- StyLua 2.6 has no Lua 5.5 syntax mode: 'global' declarations do not parse"
printf 'global x = 1\n' | stylua - 2>&1 | sed 's/(1:8 to 1:9), //'
echo "exit status: ${PIPESTATUS[1]}"
