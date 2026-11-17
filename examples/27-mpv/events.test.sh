# host: mpv
# A 3-second lavfi test pattern stands in for a video file; --vo=null and
# --ao=null play it without a window or sound card; --pause keeps time-pos still
# so the position we print does not depend on how fast the machine is.
timeout 30 mpv --no-config --vo=null --ao=null --pause --msg-level=all=no,events=info \
    --script=events.lua "av://lavfi:testsrc=duration=3:size=160x120:rate=25"
echo "mpv exit code: $?"
