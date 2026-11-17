# interp: 5.5, 5.4, jit
# The Project 5 pipelines, unchanged scripts, through the Rust host. The
# output must be byte-identical to the C++ host's expected output.
. ./build.sh
OUT=$(mktemp)
(cd $P5 &&
  echo '$ mediapipe --frames 2 scripts/brightness.lua:amount=-30,contrast=1.5 scripts/histogram.lua scripts/blur.lua' &&
  { $MP --frames 2 scripts/brightness.lua:amount=-30,contrast=1.5 scripts/histogram.lua scripts/blur.lua; echo "[exit $?]"; } &&
  echo '$ mediapipe scripts/edges.lua scripts/invert.lua' &&
  $MP scripts/edges.lua scripts/invert.lua | sed -n '/^output/,$p') > "$OUT"
diff $P5/pipeline.expected "$OUT" && echo "pipeline: identical to the C++ host ($(wc -l < "$OUT") lines)"
(cd $P5 && $MP --frames 3 scripts/ex2_motion.lua scripts/ex1_sharpen.lua:amount=1.5 scripts/ex3_mirror.lua) |
  grep -v '^  |' > "$OUT"
diff $P5/exercises.expected "$OUT" && echo "exercises: identical to the C++ host ($(wc -l < "$OUT") lines)"
rm -f "$OUT"
