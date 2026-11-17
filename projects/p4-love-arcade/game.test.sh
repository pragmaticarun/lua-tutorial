# host: love
# One autoplayed game inside real LÖVE (virtual X server, software OpenGL):
# fixed 1/60 s steps, a pixel snapshot at frame 600, and the event log, which
# must equal the plain-Lua run of the same code (steps/simulate.expected).
OUT=$(mktemp)
xvfb-run -a love game --autoplay --snapshot 600 > "$OUT"
echo "love exit status: $?"
grep -E '^(snapshot|  (paddle|brick|background) )' "$OUT"
grep -v -E '^(snapshot|  (paddle|brick|background) )' "$OUT" > "$OUT.log"
if diff steps/simulate.expected "$OUT.log" > /dev/null; then
  echo "event log: $(wc -l < "$OUT.log") lines, identical to the plain-Lua simulation"
else
  diff steps/simulate.expected "$OUT.log" | head -20
fi
tail -6 "$OUT.log"
rm -f "$OUT" "$OUT.log"
