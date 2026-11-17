# host: luarocks
TREE=$(mktemp -d)
cd ex1
luarocks lint slug-1.0-1.rockspec && echo "lint OK"
luarocks --tree="$TREE" make slug-1.0-1.rockspec > /dev/null 2>&1 && echo "installed"
luarocks --tree="$TREE" show slug --porcelain 2>/dev/null | grep -E '^(package|version|summary|license)'
(eval "$(luarocks --tree="$TREE" path)"; cd /; ${LUA54:-lua5.4} -e 'print(require("slug").slug("Hello, Rocks World!"))')
rm -rf "$TREE"
