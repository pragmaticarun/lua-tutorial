# interp: 5.5, 5.4, jit
# host: busted
# The specs on each interpreter: $BUSTED is busted (Lua 5.4), busted5.5 or
# busted-jit. TAP output has no timings, so it can be compared exactly.
"$BUSTED" -o TAP
echo "[exit $?]"
