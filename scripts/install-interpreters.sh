#!/usr/bin/env bash
# Build Lua 5.5, Lua 5.4 and LuaJIT 2.1 from source and expose them as
# lua5.5, lua5.4 and luajit.  Used by the Setup page and by CI.
#
#   PREFIX   install root            (default: /opt)
#   BINDIR   where symlinks are made (default: /usr/local/bin)
#   SUDO     command prefix for installs (default: sudo if not root)
#
# Ubuntu prerequisites: sudo apt install build-essential curl git
set -euo pipefail

LUA55_VERSION=5.5.1
LUA55_SHA256=1c4b4068d67061f2a2231ad2b5422e77acea1487ea9890f6320af614f4373dce
LUA54_VERSION=5.4.9
LUA54_SHA256=2335b6c582a52654f94612bf10d2f4672805d05329aa6568b1d8cd9e5c6fb8e6
# LuaJIT has no release tarballs; 2.1 is a rolling branch. Pin a commit so the
# course output is reproducible (2.1 version = 2.1.<commit unix timestamp>).
LUAJIT_COMMIT=63c8f1a9b479ba5518cf6a170ff7729178bc3cfd   # 2.1.1794386141

PREFIX=${PREFIX:-/opt}
BINDIR=${BINDIR:-/usr/local/bin}
if [[ -z "${SUDO+x}" ]]; then
  if [[ $(id -u) -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi
fi
MAKE=${MAKE:-make}
JOBS=$(nproc 2>/dev/null || echo 2)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

build_lua() {
  local version=$1 sha=$2 short=$3
  echo "==> Lua $version"
  curl -fsSLO "https://www.lua.org/ftp/lua-$version.tar.gz"
  echo "$sha  lua-$version.tar.gz" | sha256sum -c -
  tar xzf "lua-$version.tar.gz"
  "$MAKE" -C "lua-$version" -j"$JOBS" linux >/dev/null
  $SUDO "$MAKE" -C "lua-$version" install INSTALL_TOP="$PREFIX/lua-$version" >/dev/null
  $SUDO mkdir -p "$BINDIR"
  $SUDO ln -sf "$PREFIX/lua-$version/bin/lua" "$BINDIR/lua$short"
  $SUDO ln -sf "$PREFIX/lua-$version/bin/luac" "$BINDIR/luac$short"
  "$BINDIR/lua$short" -v
}

build_lua "$LUA55_VERSION" "$LUA55_SHA256" 5.5
build_lua "$LUA54_VERSION" "$LUA54_SHA256" 5.4

echo "==> LuaJIT 2.1 @ $LUAJIT_COMMIT"
git clone -q https://github.com/LuaJIT/LuaJIT.git luajit
git -C luajit checkout -q "$LUAJIT_COMMIT"
"$MAKE" -C luajit -j"$JOBS" PREFIX="$PREFIX/luajit-2.1" >/dev/null
$SUDO "$MAKE" -C luajit install PREFIX="$PREFIX/luajit-2.1" >/dev/null
$SUDO ln -sf "$PREFIX/luajit-2.1/bin/luajit" "$BINDIR/luajit"
"$BINDIR/luajit" -v
