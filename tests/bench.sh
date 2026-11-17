#!/usr/bin/env bash
# Run the Lesson 17 benchmarks for real and write the measured results to
# includes/bench/17-performance.md, which the lesson page includes.
# Timings are CPU time (os.clock), best of 5 runs, in milliseconds.
# Usage: tests/bench.sh
set -eu
cd "$(dirname "$0")/.."
DIR=examples/17-performance
OUT=includes/bench/17-performance.md
mkdir -p includes/bench
TMP=$(mktemp -d)
declare -A BIN=( [5.5]="${LUA55:-lua5.5}" [5.4]="${LUA54:-lua5.4}" [jit]="${LUAJIT:-luajit}" [joff]="${LUAJIT:-luajit} -joff" )
IDS=(5.5 5.4 jit joff)
# lesson order; every non-module example in the directory must be listed
ORDER="locals strings tables iteration allocation closures ex1_hoist ex2_csv ex3_memo ex4_bytes"
for f in "$DIR"/*.lua; do
  head -5 "$f" | grep -q '^-- *module *$' && continue
  [[ " $ORDER " == *" $(basename "$f" .lua) "* ]] || { echo "not in ORDER: $f" >&2; exit 1; }
done
for id in "${IDS[@]}"; do
  : > "$TMP/$id"
  for name in $ORDER; do
    (cd "$DIR" && LUA_BENCH=1 ${BIN[$id]} "$name.lua") | grep '^BENCH' >> "$TMP/$id"
  done
done
cpu=$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -1)
{
  echo "!!! info \"Measured on $(date '+%Y-%m-%d') by \`tests/bench.sh\`\""
  echo "    CPU: ${cpu:-unknown}, $(nproc) logical CPUs, $(uname -sr)."
  echo "    $(lua5.5 -v 2>&1 | head -1 | cut -d' ' -f1-2), $(lua5.4 -v 2>&1 | head -1 | cut -d' ' -f1-2) (both \`-O2\`), $(luajit -v | cut -d' ' -f1-2)."
  echo "    CPU time in milliseconds, best of 5 runs; lower is better. Shared cloud"
  echo "    machine, so treat differences under ~10% as noise. Re-run on your machine."
  echo
  echo "| Benchmark | Variant | Lua 5.5 | Lua 5.4 | LuaJIT 2.1 | LuaJIT \`-joff\` |"
  echo "|---|---|---:|---:|---:|---:|"
  while IFS=$'\t' read -r _ title label ms; do
    fmt() { if [[ "$1" == "0.00" ]]; then echo "< 0.01"; else echo "${1:-n/a}"; fi; }
    row="| $title | $label | $(fmt "$ms")"
    for id in 5.4 jit joff; do
      v=$(awk -F'\t' -v t="$title" -v l="$label" '$2==t && $3==l {print $4}' "$TMP/$id")
      row="$row | $(fmt "$v")"
    done
    echo "$row |"
  done < "$TMP/5.5"
} > "$OUT"
rm -rf "$TMP"
echo "wrote $OUT"
