# host: mpv
timeout 30 mpv --no-config --vo=null --ao=null --pause --msg-level=all=no,keybindings=info \
    --script=keybindings.lua "av://lavfi:testsrc=duration=3:size=160x120:rate=25"
echo "exit code: $?"
