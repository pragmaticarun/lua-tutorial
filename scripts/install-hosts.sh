#!/usr/bin/env bash
# Install the pinned "real world" Lua hosts used by Part 4 (lessons 23-28).
# Used by the Setup page and by CI; everything goes under $PREFIX and small
# wrapper scripts are written to $BINDIR.
#
#   install-hosts.sh [component...]   (default: all)
#   components: nvim redis openresty mpv love luarocks stylua
#
#   PREFIX   install root            (default: /opt/hosts)
#   BINDIR   where wrappers are made (default: /usr/local/bin)
#   SUDO     command prefix for BINDIR/PREFIX creation (default: sudo if not root)
#
# Each component is skipped when $PREFIX/<name>/.installed matches its pin, so
# a cached $PREFIX makes reruns instant.  Ubuntu prerequisites: build-essential
# curl git unzip libssl-dev (OpenResty/Redis/LuaRocks are compiled from source; mpv is
# compiled from source against a locked conda-forge environment, because the
# conda-forge mpv package is built without Lua).
set -euo pipefail

NVIM_VERSION=0.12.6
NVIM_SHA256=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87
REDIS_VERSION=8.10.3
REDIS_SHA256=edde778f6bdee7581e42fc139ca9e07e2822212092f7501f99989656e3629d02
OPENRESTY_VERSION=1.31.8.1
OPENRESTY_SHA256=b569c63b420f80a4ac8466f2deffe73ed93ab760026532e039c3658409a997f4
PCRE2_VERSION=10.49
PCRE2_SHA256=929f0b20e62879252a15886b06c89f1edef61a363cbd5826fb041080a5e557ae
ZLIB_VERSION=1.4
ZLIB_SHA256=02dd159783677a749c04adbdd02b55b8a2bcc7e054f51b76b549199a916ad584
MPV_VERSION=0.42.0
MPV_SHA256=bcfebbfa2b65a6d88dc97ea18117831072373e38b5785a2afb874ed4df5070dd
LOVE_VERSION=11.5
LOVE_SHA256=65a673406431eff7167a15a032bf7a2e4ba50108e091eb7b176465831f9b5e00
LUAROCKS_VERSION=3.13.0
LUAROCKS_SHA256=245bf6ec560c042cb8948e3d661189292587c5949104677f1eecddc54dbe7e37
STYLUA_VERSION=2.6.0
STYLUA_SHA256=a485f72bbfa22e4642e77a84b5edc2611a5cab7477b34e2e709dd8f78e919895
# rocks installed into the LuaRocks trees (one tree per interpreter)
BUSTED_VERSION=2.3.0-1
LUACHECK_VERSION=1.2.0-1

HERE=$(cd "$(dirname "$0")" && pwd)
PREFIX=${PREFIX:-/opt/hosts}
BINDIR=${BINDIR:-/usr/local/bin}
LUA_PREFIX=${LUA_PREFIX:-/opt}
if [[ -z "${SUDO+x}" ]]; then
  if [[ $(id -u) -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi
fi
MAKE=${MAKE:-make}
export PATH="$PATH:/sbin:/usr/sbin"   # OpenResty configure needs ldconfig
JOBS=$(nproc 2>/dev/null || echo 2)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

$SUDO mkdir -p "$PREFIX" "$BINDIR"
$SUDO chown "$(id -u):$(id -g)" "$PREFIX"

fetch() {  # url sha256 [filename]
  local url=$1 sha=$2 out=${3:-$(basename "$1")}
  curl -fsSL --retry 3 -o "$WORK/$out" "$url"
  echo "$sha  $WORK/$out" | sha256sum -c --quiet -
}
done_marker() { [[ -f "$PREFIX/$1/.installed" && "$(cat "$PREFIX/$1/.installed")" == "$2" ]]; }
mark() { echo "$2" > "$PREFIX/$1/.installed"; }
wrapper() {  # name target [extra shell before exec]
  local name=$1 target=$2 pre=${3:-}
  $SUDO tee "$BINDIR/$name" >/dev/null <<WRAP
#!/bin/sh
$pre
exec "$target" "\$@"
WRAP
  $SUDO chmod +x "$BINDIR/$name"
}

install_nvim() {
  if ! done_marker nvim "$NVIM_VERSION"; then
    echo "==> Neovim $NVIM_VERSION"
    fetch "https://github.com/neovim/neovim/releases/download/v$NVIM_VERSION/nvim-linux-x86_64.tar.gz" "$NVIM_SHA256"
    rm -rf "$PREFIX/nvim" && mkdir -p "$PREFIX/nvim"
    tar xzf "$WORK/nvim-linux-x86_64.tar.gz" -C "$PREFIX/nvim" --strip-components=1
    mark nvim "$NVIM_VERSION"
  fi
  wrapper nvim "$PREFIX/nvim/bin/nvim"
}

install_redis() {
  if ! done_marker redis "$REDIS_VERSION"; then
    echo "==> Redis $REDIS_VERSION"
    fetch "https://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz" "$REDIS_SHA256"
    tar xzf "$WORK/redis-$REDIS_VERSION.tar.gz" -C "$WORK"
    # core server only (src/): Redis 8's top-level Makefile also builds the
    # bundled modules (JSON, search, ...), which this course does not need.
    "$MAKE" -C "$WORK/redis-$REDIS_VERSION/src" -j"$JOBS" BUILD_TLS=no >/dev/null
    rm -rf "$PREFIX/redis"
    "$MAKE" -C "$WORK/redis-$REDIS_VERSION/src" install PREFIX="$PREFIX/redis" >/dev/null
    mark redis "$REDIS_VERSION"
  fi
  wrapper redis-server "$PREFIX/redis/bin/redis-server"
  wrapper redis-cli "$PREFIX/redis/bin/redis-cli"
}

install_openresty() {
  if ! done_marker openresty "$OPENRESTY_VERSION"; then
    echo "==> OpenResty $OPENRESTY_VERSION (PCRE2 $PCRE2_VERSION, zlib $ZLIB_VERSION, system OpenSSL)"
    fetch "https://openresty.org/download/openresty-$OPENRESTY_VERSION.tar.gz" "$OPENRESTY_SHA256"
    fetch "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$PCRE2_VERSION/pcre2-$PCRE2_VERSION.tar.gz" "$PCRE2_SHA256"
    fetch "https://github.com/madler/zlib/releases/download/v$ZLIB_VERSION/zlib-$ZLIB_VERSION.tar.gz" "$ZLIB_SHA256"
    for f in openresty-$OPENRESTY_VERSION pcre2-$PCRE2_VERSION zlib-$ZLIB_VERSION; do
      tar xzf "$WORK/$f.tar.gz" -C "$WORK"
    done
    rm -rf "$PREFIX/openresty"
    (cd "$WORK/openresty-$OPENRESTY_VERSION" &&
      ./configure --prefix="$PREFIX/openresty" -j"$JOBS" \
        --with-pcre="$WORK/pcre2-$PCRE2_VERSION" --with-pcre-jit \
        --with-zlib="$WORK/zlib-$ZLIB_VERSION" >/dev/null &&
      "$MAKE" -j"$JOBS" >/dev/null && "$MAKE" install >/dev/null)
    mark openresty "$OPENRESTY_VERSION"
  fi
  wrapper openresty "$PREFIX/openresty/bin/openresty"
  wrapper resty "$PREFIX/openresty/bin/resty"
}

install_mpv() {
  if ! done_marker mpv "$MPV_VERSION"; then
    echo "==> mpv $MPV_VERSION (built against a locked conda-forge env, Lua = LuaJIT)"
    local mm=$WORK/bin/micromamba env=$PREFIX/mpv-env
    curl -fsSL --retry 3 https://micro.mamba.pm/api/micromamba/linux-64/2.10.0 | tar -xj -C "$WORK" bin/micromamba
    rm -rf "$env" "$PREFIX/mpv"
    MAMBA_ROOT_PREFIX=$WORK/mamba "$mm" create -y -q -p "$env" --file "$HERE/hosts/mpv-env.lock" >/dev/null
    fetch "https://github.com/mpv-player/mpv/archive/refs/tags/v$MPV_VERSION.tar.gz" "$MPV_SHA256" mpv.tar.gz
    tar xzf "$WORK/mpv.tar.gz" -C "$WORK"
    (cd "$WORK/mpv-$MPV_VERSION" &&
      PATH=$env/bin:$PATH PKG_CONFIG_PATH=$env/lib/pkgconfig:$env/share/pkgconfig \
      CC=$env/bin/x86_64-conda-linux-gnu-gcc \
      "$env/bin/meson" setup build --prefix="$PREFIX/mpv" --buildtype=release \
        -Dauto_features=disabled -Dgl=disabled -Dlibavdevice=enabled -Diconv=enabled \
        -Dlua=luajit -Dlibmpv=false -Dmanpage-build=disabled -Dhtml-build=disabled \
        -Dc_link_args="-Wl,-rpath,$env/lib" >/dev/null &&
      PATH=$env/bin:$PATH "$env/bin/ninja" -C build install >/dev/null)
    # drop the compiler toolchain and headers: only the runtime libraries
    # in $env/lib are needed by mpv (via its rpath); keeps the CI cache small
    rm -rf "$env/x86_64-conda-linux-gnu" "$env/libexec" "$env/include" "$env/lib/gcc" \
           "$env/share/doc" "$env/share/man"
    mark mpv "$MPV_VERSION"
  fi
  wrapper mpv "$PREFIX/mpv/bin/mpv"
}

install_love() {
  if ! done_marker love "$LOVE_VERSION"; then
    echo "==> LÖVE $LOVE_VERSION (AppImage, extracted)"
    fetch "https://github.com/love2d/love/releases/download/$LOVE_VERSION/love-$LOVE_VERSION-x86_64.AppImage" "$LOVE_SHA256" love.AppImage
    chmod +x "$WORK/love.AppImage"
    rm -rf "$PREFIX/love"
    (cd "$WORK" && ./love.AppImage --appimage-extract >/dev/null && mv squashfs-root "$PREFIX/love")
    mark love "$LOVE_VERSION"
  fi
  wrapper love "$PREFIX/love/AppRun"
}

install_luarocks() {
  if ! done_marker luarocks "$LUAROCKS_VERSION $BUSTED_VERSION $LUACHECK_VERSION"; then
    echo "==> LuaRocks $LUAROCKS_VERSION + busted $BUSTED_VERSION + luacheck $LUACHECK_VERSION"
    fetch "https://luarocks.org/releases/luarocks-$LUAROCKS_VERSION.tar.gz" "$LUAROCKS_SHA256"
    tar xzf "$WORK/luarocks-$LUAROCKS_VERSION.tar.gz" -C "$WORK"
    rm -rf "$PREFIX/luarocks"
    (cd "$WORK/luarocks-$LUAROCKS_VERSION" &&
      ./configure --prefix="$PREFIX/luarocks" --with-lua="$LUA_PREFIX/lua-5.4.9" >/dev/null &&
      "$MAKE" >/dev/null && "$MAKE" install >/dev/null)
    local lr=$PREFIX/luarocks/bin/luarocks
    # one rocks tree per interpreter, so busted can run on each of them
    for spec in "5.4:$LUA_PREFIX/lua-5.4.9" "5.5:$LUA_PREFIX/lua-5.5.1" "5.1:$LUA_PREFIX/luajit-2.1"; do
      local v=${spec%%:*} dir=${spec#*:} tree=$PREFIX/rocks-${spec%%:*}
      [[ $v == 5.1 ]] && tree=$PREFIX/rocks-jit
      "$lr" --lua-version="$v" --lua-dir="$dir" --tree="$tree" install busted "$BUSTED_VERSION" >/dev/null
      "$lr" --lua-version="$v" --lua-dir="$dir" --tree="$tree" install luacheck "$LUACHECK_VERSION" >/dev/null
    done
    mark luarocks "$LUAROCKS_VERSION $BUSTED_VERSION $LUACHECK_VERSION"
  fi
  wrapper luarocks "$PREFIX/luarocks/bin/luarocks"
  wrapper busted "$PREFIX/rocks-5.4/bin/busted"
  wrapper busted5.5 "$PREFIX/rocks-5.5/bin/busted"
  wrapper busted-jit "$PREFIX/rocks-jit/bin/busted"
  wrapper luacheck "$PREFIX/rocks-5.4/bin/luacheck"
}

install_stylua() {
  if ! done_marker stylua "$STYLUA_VERSION"; then
    echo "==> StyLua $STYLUA_VERSION"
    fetch "https://github.com/JohnnyMorganz/StyLua/releases/download/v$STYLUA_VERSION/stylua-linux-x86_64.zip" "$STYLUA_SHA256"
    rm -rf "$PREFIX/stylua" && mkdir -p "$PREFIX/stylua"
    unzip -q "$WORK/stylua-linux-x86_64.zip" -d "$PREFIX/stylua"
    chmod +x "$PREFIX/stylua/stylua"
    mark stylua "$STYLUA_VERSION"
  fi
  wrapper stylua "$PREFIX/stylua/stylua"
}

components=("$@")
[[ ${#components[@]} -eq 0 ]] && components=(nvim redis openresty mpv love luarocks stylua)
for c in "${components[@]}"; do "install_$c"; done
