# host: mpv
timeout 30 mpv --no-config --vo=null --ao=null --pause --msg-level=all=no,osd=info \
    --script=osd.lua "av://lavfi:testsrc=duration=3:size=640x360:rate=25"
