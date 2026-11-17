# host: mpv
timeout 30 mpv --no-config --vo=null --ao=null --pause --msg-level=all=no,properties=info \
    --script=properties.lua "av://lavfi:testsrc=duration=3:size=320x240:rate=25"
