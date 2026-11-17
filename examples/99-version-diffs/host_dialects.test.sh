# host: nvim, love, openresty, mpv, redis
# The same probe (host_probe.lua), run inside every embedding host of Part 4.
PROBE=$(cat host_probe.lua)
echo "Neovim:"
D=$(mktemp -d); { printf 'local r = (function()\n%s\nend)()\nio.write(r, "\\n")\n' "$PROBE"; } > "$D/p.lua"
nvim --headless --clean -l "$D/p.lua"; rm -rf "$D"
echo "LÖVE:"
D=$(mktemp -d); { printf 'local r = (function()\n%s\nend)()\n' "$PROBE"; echo 'function love.load() print(r) love.event.quit() end'; } > "$D/main.lua"
echo 'function love.conf(t) t.modules.audio = false t.modules.sound = false end' > "$D/conf.lua"
xvfb-run -a love "$D"; rm -rf "$D"
echo "OpenResty (resty CLI):"
D=$(mktemp -d); { printf 'local r = (function()\n%s\nend)()\nprint(r)\n' "$PROBE"; } > "$D/p.lua"
resty "$D/p.lua"; rm -rf "$D"
echo "mpv:"
D=$(mktemp -d); { printf 'local r = (function()\n%s\nend)()\nio.write(r, "\\n")\nmp.command("quit")\n' "$PROBE"; } > "$D/p.lua"
mpv --no-config --vo=null --ao=null --msg-level=all=no --script="$D/p.lua" "av://lavfi:testsrc=duration=1"; rm -rf "$D"
echo "Redis (EVAL):"
redis-cli -p "${REDIS_PORT:-6379}" --raw EVAL "$PROBE" 0
