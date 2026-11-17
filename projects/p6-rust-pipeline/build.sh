# Build the Rust host for the interpreter the test runner chose: one Cargo
# feature per Lua, linked statically against the course's own build of it.
case $LUA_ID in 5.5) FEATURE=lua55 ;; 5.4) FEATURE=lua54 ;; jit) FEATURE=luajit ;; esac
LUA_LIB="$LUA_LIBDIR" LUA_LIB_NAME="$LUA_LIBNAME" LUA_LINK=static \
  cargo build --release --locked --quiet --no-default-features --features "$FEATURE" \
  --target-dir "target/$LUA_ID" || exit 1
MP=$PWD/target/$LUA_ID/release/mediapipe
P5=../p5-cpp-pipeline              # the scripts and expected output of the C++ host
