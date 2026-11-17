# host: mpv
# 100 s at 1 frame/s, encoded to a real file so "duration" is known
MEDIA=$(mktemp --suffix=.mkv)
mpv --no-config --really-quiet --o="$MEDIA" --ovc=mpeg4 "av://lavfi:testsrc=duration=100:size=160x120:rate=1"
timeout 30 mpv --no-config --vo=null --ao=null --pause --msg-level=all=no,ex4_clock=info \
    --script=ex4_clock.lua "$MEDIA"
rm -f "$MEDIA"
