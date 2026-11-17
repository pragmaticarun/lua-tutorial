# host: busted
# Run the specs on each interpreter (one LuaRocks tree each: busted = Lua 5.4,
# busted5.5, busted-jit). -o TAP gives stable output; the default output
# includes timings.
cd textkit
echo "--- busted (Lua 5.4)"
busted -o TAP
for b in busted5.5 busted-jit; do
  out=$($b -o TAP)
  echo "--- $b: $(grep -c '^ok' <<< "$out") ok, $(grep -c '^not ok' <<< "$out") not ok"
done
echo "--- a failing spec: non-zero exit, and TAP says which assertion failed"
busted -o TAP ../failing_spec.lua > failing.out
echo "exit status: $?"
sed -n '1,5p' failing.out       # the rest prints table addresses, which vary
rm -f failing.out
