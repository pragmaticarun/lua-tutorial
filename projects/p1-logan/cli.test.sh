# interp: 5.5, 5.4, jit
# Run the command from the checkout on the interpreter in $LUA (the test
# runner sets it to Lua 5.5, 5.4 and LuaJIT in turn; the output must match).
logan() { LUA_PATH="src/?.lua;src/?/init.lua;;" "$LUA" bin/logan "$@"; echo "[exit $?]"; }
echo '$ logan --top 3 data/access.log'
logan --top 3 data/access.log
echo
echo '$ logan -n 2 -s 4xx,500 -o json data/access.log'
logan -n 2 -s 4xx,500 -o json data/access.log
echo
echo '$ grep ERROR data/app.log | logan -n 2 -'
grep ERROR data/app.log | logan -n 2 -
echo
echo '$ logan --top lots data/access.log'
logan --top lots data/access.log 2>&1
echo '$ logan -n 1 data/app.log nope.log   # first two lines and the exit status'
logan -n 1 data/app.log nope.log 2>&1 | sed -n '1,2p;$p'
