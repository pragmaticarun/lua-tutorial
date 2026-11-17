#!/usr/bin/env bash
# Run every example under examples/ on every interpreter and compare stdout
# with the matching expected-output file.
#
# Conventions (see CONTRIBUTING.md):
#   examples/NN-slug/name.lua             the snippet
#   examples/NN-slug/name.expected        expected stdout (shown in the docs)
#   examples/NN-slug/name.<id>.expected   optional per-interpreter override,
#                                         <id> is one of: 5.5 5.4 jit
#   first lines may contain:  -- targets: 5.5, 5.4    (default: all)
#                             -- stdin: name.input    (file fed on stdin)
#
# Interpreter binaries can be overridden with LUA55, LUA54, LUAJIT.
# Usage: tests/run_all.sh [-v] [filter-substring]
set -u
cd "$(dirname "$0")/.."
ROOT=$PWD

VERBOSE=0
if [[ "${1:-}" == "-v" ]]; then VERBOSE=1; shift; fi
FILTER="${1:-}"

declare -A BIN=( [5.5]="${LUA55:-lua5.5}" [5.4]="${LUA54:-lua5.4}" [jit]="${LUAJIT:-luajit}" )
IDS=(5.5 5.4 jit)
declare -A PASS FAIL SKIP
for id in "${IDS[@]}"; do PASS[$id]=0; FAIL[$id]=0; SKIP[$id]=0; done
FAILURES=()

mkdir -p tests/results
VERS=tests/results/versions.txt
: > "$VERS"
for id in "${IDS[@]}"; do
  if ! command -v "${BIN[$id]}" >/dev/null 2>&1; then
    echo "error: interpreter '${BIN[$id]}' ($id) not found" >&2; exit 2
  fi
  v=$("${BIN[$id]}" -v 2>&1 | head -1)
  echo "$id	$v" >> "$VERS"
done

# per-lesson results: lesson -> "id:pass:fail:skip ..."
declare -A LP LF LS

targets_of() {
  local t
  t=$(head -5 "$1" | sed -n 's/^-- *targets: *//p' | head -1)
  if [[ -z "$t" ]]; then echo "5.5 5.4 jit"; else echo "$t" | tr ',' ' '; fi
}

while IFS= read -r f; do
  rel=${f#./}
  [[ -n "$FILTER" && "$rel" != *"$FILTER"* ]] && continue
  dir=$(dirname "$rel"); base=$(basename "$rel" .lua); lesson=$(basename "$dir")
  default_exp="$dir/$base.expected"
  if [[ ! -f "$default_exp" ]]; then
    echo "MISSING expected file: $default_exp" >&2
    FAILURES+=("$rel (no .expected)"); continue
  fi
  tg=" $(targets_of "$rel") "
  stdin_file=$(head -5 "$rel" | sed -n 's/^-- *stdin: *//p' | head -1)
  for id in "${IDS[@]}"; do
    key="$lesson|$id"
    if [[ "$tg" != *" $id "* ]]; then
      SKIP[$id]=$(( SKIP[$id] + 1 )); LS[$key]=$(( ${LS[$key]:-0} + 1 ))
      continue
    fi
    exp="$dir/$base.$id.expected"; [[ -f "$exp" ]] || exp=$default_exp
    if [[ -n "$stdin_file" ]]; then
      out=$(cd "$dir" && timeout 20 "${BIN[$id]}" "$base.lua" < "$stdin_file" 2>/tmp/lua-test-stderr); rc=$?
    else
      out=$(cd "$dir" && timeout 20 "${BIN[$id]}" "$base.lua" < /dev/null 2>/tmp/lua-test-stderr); rc=$?
    fi
    if [[ $rc -eq 0 ]] && diff -u "$exp" <(printf '%s\n' "$out") > /tmp/lua-test-diff 2>&1; then
      PASS[$id]=$(( PASS[$id] + 1 )); LP[$key]=$(( ${LP[$key]:-0} + 1 ))
      [[ $VERBOSE -eq 1 ]] && echo "PASS [$id] $rel"
    else
      FAIL[$id]=$(( FAIL[$id] + 1 )); LF[$key]=$(( ${LF[$key]:-0} + 1 ))
      FAILURES+=("[$id] $rel (exit $rc)")
      echo "FAIL [$id] $rel (exit $rc)"
      sed 's/^/    /' /tmp/lua-test-diff | head -30
      sed 's/^/    stderr: /' /tmp/lua-test-stderr | head -10
    fi
  done
done < <(cd "$ROOT" && find ./examples -name '*.lua' | sort)

# Badge snippets: one per lesson, listing only the interpreters on which
# every applicable example passed.
mkdir -p includes/badges
declare -A NAME=( [5.5]="Lua 5.5" [5.4]="Lua 5.4" [jit]="LuaJIT 2.1" )
if [[ -z "$FILTER" ]]; then
  for d in examples/*/; do
    lesson=$(basename "$d")
    parts=(); names=()
    for id in "${IDS[@]}"; do
      key="$lesson|$id"; p=${LP[$key]:-0}; fl=${LF[$key]:-0}; s=${LS[$key]:-0}
      full=$(awk -F'\t' -v i="$id" '$1==i{print $2}' "$VERS" | awk '{print $1" "$2}')
      if [[ $fl -eq 0 && $p -gt 0 ]]; then
        names+=("$full")
        if [[ $s -gt 0 ]]; then parts+=("$full: $p examples passed ($s written for other versions only)")
        else parts+=("$full: $p examples passed"); fi
      fi
    done
    {
      if [[ ${#names[@]} -eq 0 ]]; then
        printf '!!! failure "Not yet passing on any interpreter"\n'
      else
        title=$(printf '%s · ' "${names[@]}"); title=${title% · }
        printf '??? success "Tested with %s"\n' "$title"
        for p in "${parts[@]}"; do printf '    - %s\n' "$p"; done
      fi
      printf '\n    Every code block on this page is a real file under `examples/%s/`, run on each\n' "$lesson"
      printf '    interpreter by `tests/run_all.sh` and compared with its `.expected` output.\n'
    } > "includes/badges/$lesson.md"
  done
fi

echo
echo "Interpreters:"; sed 's/^/  /' "$VERS"
echo
printf '%-6s %6s %6s %6s\n' interp pass fail skip
for id in "${IDS[@]}"; do printf '%-6s %6d %6d %6d\n' "$id" "${PASS[$id]}" "${FAIL[$id]}" "${SKIP[$id]}"; done
if [[ ${#FAILURES[@]} -gt 0 ]]; then
  echo; echo "Failures:"; printf '  %s\n' "${FAILURES[@]}"; exit 1
fi
echo; echo "All examples passed."
