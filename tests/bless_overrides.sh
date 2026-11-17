#!/usr/bin/env bash
# Authoring helper: for the given example files, write NAME.<id>.expected for
# every target interpreter whose stdout differs from NAME.expected.
# Use ONLY for intentional, documented version differences, and review them.
set -u
cd "$(dirname "$0")/.."
declare -A BIN=( [5.5]="${LUA55:-lua5.5}" [5.4]="${LUA54:-lua5.4}" [jit]="${LUAJIT:-luajit}" )
for f in "$@"; do
  dir=$(dirname "$f"); base=$(basename "$f" .lua)
  t=$(head -5 "$f" | sed -n 's/^-- *targets: *//p' | head -1 | tr ',' ' ')
  stdin_file=$(head -5 "$f" | sed -n 's/^-- *stdin: *//p' | head -1)
  for id in ${t:-5.5 5.4 jit}; do
    out=$(cd "$dir" && "${BIN[$id]}" "$base.lua" < "${stdin_file:-/dev/null}")
    if [[ "$(printf '%s\n' "$out")" != "$(cat "$dir/$base.expected")" ]]; then
      printf '%s\n' "$out" > "$dir/$base.$id.expected"; echo "override $dir/$base.$id.expected"
    fi
  done
done
