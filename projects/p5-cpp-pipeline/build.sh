# Configure and build mediapipe for the interpreter the test runner chose
# ($LUA_ID, $LUA_INC, $LUA_LIBDIR, $LUA_LIBNAME), into build/$LUA_ID.
cmake -S . -B "build/$LUA_ID" -DCMAKE_BUILD_TYPE=Release \
  -DLUA_INCLUDE_DIR="$LUA_INC" -DLUA_LIBRARY="$LUA_LIBDIR/lib$LUA_LIBNAME.a" > "build-$LUA_ID.log" 2>&1 &&
cmake --build "build/$LUA_ID" -j 4 >> "build-$LUA_ID.log" 2>&1 || { cat "build-$LUA_ID.log" >&2; exit 1; }
rm -f "build-$LUA_ID.log"
MP=build/$LUA_ID/mediapipe
