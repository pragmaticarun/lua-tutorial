# interp: 5.5, 5.4, jit
# The two outputs that differ by interpreter (version.<id>.expected):
# the version line, and the error for a precompiled chunk, which every
# version refuses in mode "t" with its own wording.
. ./build.sh
$MP --version
TMP=$(mktemp -d)
"$LUA" -e 'io.write(string.dump(function() return 1 end))' > "$TMP/compiled.lua"
$MP "$TMP/compiled.lua" | grep FAILED | sed "s#$TMP/##"
rm -rf "$TMP"
