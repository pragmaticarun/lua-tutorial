# interp: 5.5, 5.4, jit
# Hostile scripts: each one is stopped and unloaded; the good filter at the
# end still runs on every frame.
. ./build.sh
$MP --frames 2 --memory 512 hostile/escape.lua hostile/loop.lua hostile/pcall_loop.lua \
    hostile/memory.lua hostile/half_done.lua hostile/keep_frame.lua hostile/no_process.lua \
    scripts/invert.lua | grep -v '^  |'
echo "[exit ${PIPESTATUS[0]}]"
echo '$ mediapipe --instructions 100000000000 --seconds 0.2 hostile/loop.lua'
$MP --instructions 100000000000 --seconds 0.2 hostile/loop.lua | grep FAILED
echo '$ mediapipe --frames 1 --seconds 0.1 hostile/backtrack.lua scripts/invert.lua'
$MP --frames 1 --seconds 0.1 hostile/backtrack.lua scripts/invert.lua | grep -E 'FAILED|invert'
echo '$ mediapipe --memory 16 scripts/invert.lua'
$MP --memory 16 scripts/invert.lua | grep FAILED
