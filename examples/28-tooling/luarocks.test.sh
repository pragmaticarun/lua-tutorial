# host: luarocks
# Build and install the textkit rock into a throw-away tree, offline, for
# each interpreter, then require it from that tree.
LUA_PREFIX=${LUA_PREFIX:-/opt}
TREE=$(mktemp -d)
cd textkit
echo "--- luarocks lint"
luarocks lint textkit-0.1.0-1.rockspec && echo "rockspec OK"
for spec in "5.4 lua-5.4.9 lua" "5.5 lua-5.5.1 lua" "5.1 luajit-2.1 luajit"; do
  set -- $spec
  echo "--- luarocks make for Lua $1 ($2)"
  LR="luarocks --lua-version=$1 --lua-dir=$LUA_PREFIX/$2 --tree=$TREE/$1"
  $LR make textkit-0.1.0-1.rockspec > /dev/null && echo "installed"
  $LR list --porcelain | cut -f1,2
  # `luarocks path` prints the LUA_PATH/LUA_CPATH that find the tree
  (eval "$($LR path)"; "$LUA_PREFIX/$2/bin/$3" -e '
    local t = require("textkit")
    print(_VERSION, t._VERSION, t.slugify("Built With LuaRocks"), table.concat(t.wrap("a b c d", 3), "|"))')
done
rm -rf "$TREE"
