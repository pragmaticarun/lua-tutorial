#!/usr/bin/env bash
# Run the benchmarks of Lessons 17 and 19 for real and write the measured
# results to includes/bench/*.md, which the lesson pages include.
# Timings are CPU time (os.clock), best of 5 runs, in milliseconds.
# Usage: tests/bench.sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p includes/bench
declare -A BIN=( [5.5]="${LUA55:-lua5.5}" [5.4]="${LUA54:-lua5.4}" [jit]="${LUAJIT:-luajit}" [joff]="${LUAJIT:-luajit} -joff" )
declare -A COL=( [5.5]="Lua 5.5" [5.4]="Lua 5.4" [jit]="LuaJIT 2.1" [joff]="LuaJIT \`-joff\`" )
fmt() { if [[ "${1:-}" == "0.00" ]]; then echo "< 0.01"; else echo "${1:-n/a}"; fi; }

# bench_lesson DIR OUTFILE "IDS" "ORDER"
bench_lesson() {
  local dir=$1 out=$2 ids=($3) order=$4 tmp f id
  tmp=$(mktemp -d)
  for f in "$dir"/*.lua; do      # every benchmark (uses require("bench")) must be in ORDER
    grep -q 'require("bench")' "$f" || continue
    head -5 "$f" | grep -q '^-- *module *$' && continue
    [[ " $order " == *" $(basename "$f" .lua) "* ]] || { echo "not in ORDER: $f" >&2; exit 1; }
  done
  for id in "${ids[@]}"; do
    : > "$tmp/$id"
    for name in $order; do
      (cd "$dir" && LUA_BENCH=1 ${BIN[$id]} "$name.lua") | grep '^BENCH' >> "$tmp/$id"
    done
  done
  local cpu; cpu=$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -1)
  {
    echo "!!! info \"Measured on $(date '+%Y-%m-%d') by \`tests/bench.sh\`\""
    echo "    CPU: ${cpu:-unknown}, $(nproc) logical CPUs, $(uname -sr)."
    echo "    $(lua5.5 -v 2>&1 | head -1 | cut -d' ' -f1-2), $(lua5.4 -v 2>&1 | head -1 | cut -d' ' -f1-2) (both \`-O2\`), $(luajit -v | cut -d' ' -f1-2)."
    echo "    CPU time in milliseconds, best of 5 runs; lower is better. Shared cloud"
    echo "    machine, so treat differences under ~10% as noise. Re-run on your machine."
    echo
    local hdr="| Benchmark | Variant |" sep="|---|---|"
    for id in "${ids[@]}"; do hdr="$hdr ${COL[$id]} |"; sep="$sep---:|"; done
    echo "$hdr"; echo "$sep"
    while IFS=$'\t' read -r _ title label ms; do
      local row="| $title | $label | $(fmt "$ms")" v
      for id in "${ids[@]:1}"; do
        v=$(awk -F'\t' -v t="$title" -v l="$label" '$2==t && $3==l {print $4}' "$tmp/$id")
        row="$row | $(fmt "$v")"
      done
      echo "$row |"
    done < "$tmp/${ids[0]}"
  } > "$out"
  rm -rf "$tmp"
  echo "wrote $out"
}

bench_lesson examples/17-performance includes/bench/17-performance.md "5.5 5.4 jit joff" \
  "locals strings tables iteration allocation closures ex1_hoist ex2_csv ex3_memo ex4_bytes"
bench_lesson examples/19-ffi includes/bench/19-ffi.md "jit joff" "ffi_perf"
