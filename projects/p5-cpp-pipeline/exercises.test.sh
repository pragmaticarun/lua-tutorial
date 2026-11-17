# interp: 5.5, 5.4, jit
# The exercise solutions (scripts/ex*.lua) in a real pipeline.
. ./build.sh
$MP --frames 3 scripts/ex2_motion.lua scripts/ex1_sharpen.lua:amount=1.5 scripts/ex3_mirror.lua | grep -v '^  |'
