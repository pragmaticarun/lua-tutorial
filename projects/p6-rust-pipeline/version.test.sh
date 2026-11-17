# interp: 5.5, 5.4, jit
# Per-interpreter output (version.<id>.expected): the version line and the
# refusal of a precompiled chunk.
. ./build.sh
$MP --version
TMP=$(mktemp -d)
"$LUA" -e 'io.write(string.dump(function() return 1 end))' > "$TMP/compiled.lua"
$MP "$TMP/compiled.lua" | grep FAILED | sed "s#$TMP/##"
rm -rf "$TMP"
