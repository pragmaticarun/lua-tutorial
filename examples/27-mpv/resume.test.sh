# host: mpv
STATE=$(mktemp -u).json
SRC="av://lavfi:testsrc=duration=5:size=160x120:rate=25"
run() {
  timeout 30 mpv --no-config --vo=null --ao=null --pause --msg-level=all=no,resume=info \
      --script=resume.lua --script-opts="resume-state_file=$STATE,$1" "$SRC"
}
echo "--- first run: seek to 2.5 and quit"
run resume-demo_seek=2.5
echo "--- second run: resumes"
run resume-demo_seek=-1
echo "--- state file"
python3 -c 'import json,sys; print({k[:6] + "...": v for k, v in json.load(open(sys.argv[1])).items()})' "$STATE"
rm -f "$STATE"
