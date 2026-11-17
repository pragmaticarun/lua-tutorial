# interp: 5.5, 5.4, jit
# host: luarocks
# Build the rock for this interpreter into a throw-away tree (offline: the
# rockspec has no dependencies beyond Lua), then run the installed command.
TREE=$(mktemp -d)
LV=$("$LUA" -e 'print(jit and "5.1" or _VERSION:match("%d+%.%d+"))')
LR="luarocks --lua-version=$LV --lua-dir=$LUA_PREFIX --tree=$TREE"
luarocks lint logan-1.0.0-1.rockspec && echo "lint: ok"
$LR make logan-1.0.0-1.rockspec > "$TREE/make.log" 2>&1 && echo "make: installed" || cat "$TREE/make.log"
$LR list --porcelain | cut -f1,2
echo "modules:"; (cd "$TREE" && find . -name '*.lua' -path '*logan*' | sed 's#.*/lua/[0-9.]*/#  #' | sort)
# luarocks writes a wrapper script in TREE/bin that sets the paths
"$TREE/bin/logan" -n 1 -o json data/access.log | cut -c1-60
echo "[exit ${PIPESTATUS[0]}]"
rm -rf "$TREE"
