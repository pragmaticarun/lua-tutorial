# interp: 5.5, 5.4, jit
# Exercise 1: param() in the Rust host, with a good and a bad value.
. ./build.sh
echo '$ mediapipe --frames 1 scripts/ex1_param.lua:gain=0.5,label=half'
$MP --frames 1 scripts/ex1_param.lua:gain=0.5,label=half | grep -v '^  |'
echo '$ mediapipe --frames 1 scripts/ex1_param.lua:gain=loud'
$MP --frames 1 scripts/ex1_param.lua:gain=loud | grep -v '^  |'
