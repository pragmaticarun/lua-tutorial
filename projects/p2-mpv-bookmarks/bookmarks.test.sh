# host: mpv
# Two mpv sessions with the real bookmarks script and a driver script that
# presses the keys. The bookmarks file written by the first session is read
# back by the second.
DIR=$(mktemp -d)
MEDIA=$DIR/talk.mkv
# a 10 s test video with a real duration (lavfi sources have none)
mpv --no-config --really-quiet --o="$MEDIA" --ovc=mpeg4 "av://lavfi:testsrc=duration=10:size=160x120:rate=25"
play() {
  timeout 60 mpv --no-config --vo=null --ao=null --pause --idle=no \
    --msg-level=all=no,bookmarks=info,driver=info \
    --script=bookmarks --script=tests/driver.lua \
    --script-opts="bookmarks-dir=$DIR/marks,driver-scenario=$1" "$MEDIA"
  echo "[mpv exit $?]"
}
mkdir -p "$DIR/marks"
echo "=== session 1"
play first
echo "=== the file it saved: $(ls "$DIR/marks")"
cat "$DIR/marks/talk.mkv.bookmarks"
echo "=== session 2"
play second
rm -rf "$DIR"
