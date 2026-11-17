# host: mpv
timeout 30 mpv --no-config --vo=null --ao=null --pause --msg-level=all=no,ex2_speed_keys=info \
    --script=ex2_speed_keys.lua "av://lavfi:testsrc=duration=5:size=160x120:rate=25"
