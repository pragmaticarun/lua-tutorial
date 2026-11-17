# host: mpv
# lavfi streams have no known duration, and mpv drops chapters it cannot
# place, so first encode 5 s of test pattern to a real file (mpv --o).
MEDIA=$(mktemp --suffix=.mkv)
mpv --no-config --really-quiet --o="$MEDIA" --ovc=mpeg4 "av://lavfi:testsrc=duration=5:size=160x120:rate=25"
timeout 30 mpv --no-config --vo=null --ao=null --pause --msg-level=all=no,ex3_skip_intro=info \
    --script=ex3_skip_intro.lua "$MEDIA"
rm -f "$MEDIA"
