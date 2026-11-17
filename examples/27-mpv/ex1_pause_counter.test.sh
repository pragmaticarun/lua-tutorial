# host: mpv
timeout 30 mpv --no-config --vo=null --ao=null --msg-level=all=no,ex1_pause_counter=info \
    --script=ex1_pause_counter.lua "av://lavfi:testsrc=duration=5:size=160x120:rate=25"
