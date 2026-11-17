#!/usr/bin/env bash
# Authoring helper: create missing .expected files by running each example on
# its first target interpreter. ALWAYS review the generated output by hand
# before committing; run_all.sh is the real test.
# Usage: tests/bless.sh [filter-substring]
set -u
cd "$(dirname "$0")/.."
declare -A BIN=( [5.5]="${LUA55:-lua5.5}" [5.4]="${LUA54:-lua5.4}" [jit]="${LUAJIT:-luajit}" )
find examples -name '*.lua' | sort | while read -r f; do
  [[ -n "${1:-}" && "$f" != *"$1"* ]] && continue
  dir=$(dirname "$f"); base=$(basename "$f" .lua)
  [[ -f "$dir/$base.expected" ]] && continue
  t=$(head -5 "$f" | sed -n 's/^-- *targets: *//p' | head -1 | tr ',' ' ')
  id=$(echo "${t:-5.5}" | awk '{print $1}')
  stdin_file=$(head -5 "$f" | sed -n 's/^-- *stdin: *//p' | head -1)
  (cd "$dir" && "${BIN[$id]}" "$base.lua" < "${stdin_file:-/dev/null}") > "$dir/$base.expected"
  echo "blessed $dir/$base.expected ($id)"
done

