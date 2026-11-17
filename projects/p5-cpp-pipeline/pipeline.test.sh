# interp: 5.5, 5.4, jit
# Build with CMake against this interpreter, then run two pipelines.
. ./build.sh
echo '$ mediapipe --frames 2 scripts/brightness.lua:amount=-30,contrast=1.5 scripts/histogram.lua scripts/blur.lua'
$MP --frames 2 scripts/brightness.lua:amount=-30,contrast=1.5 scripts/histogram.lua scripts/blur.lua
echo "[exit $?]"
echo '$ mediapipe scripts/edges.lua scripts/invert.lua'
$MP scripts/edges.lua scripts/invert.lua | sed -n '/^output/,$p'
