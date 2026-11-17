# host: mpv
# Exercise 4 in real mpv: a saved bookmarks file, then Ctrl+a at 5 s and at 9 s.
DIR=$(mktemp -d)
mpv --no-config --really-quiet --o="$DIR/talk.mkv" --ovc=mpeg4 "av://lavfi:testsrc=duration=10:size=160x120:rate=25"
printf '2.000\tIntro over\n4.200\tDemo\n7.520\tCredits\n' > "$DIR/talk.mkv.bookmarks"
for at in 5 9; do
  timeout 30 mpv --no-config --vo=null --ao=null --pause --msg-level=all=no,ex4_abloop=info \
    --script=ex4_abloop.lua --script-opts="abloop-file=$DIR/talk.mkv.bookmarks,abloop-demo_at=$at" \
    "$DIR/talk.mkv"
done
rm -rf "$DIR"
