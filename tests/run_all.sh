#!/usr/bin/env bash
# Build and run every example under examples/ on every interpreter and compare
# stdout with the matching expected-output file.
#
# Conventions (see CONTRIBUTING.md):
#   examples/NN-slug/name.lua             a Lua snippet
#   examples/NN-slug/name.c / name.cpp    a C / C++ snippet (needs a "build:" header)
#   examples/NN-slug/<crate>/src/bin/name.rs   a Rust binary in a Cargo crate
#   name.expected                         expected stdout, next to the source
#   name.<id>.expected                    optional per-interpreter override,
#                                         <id> is one of: 5.5 5.4 jit
# Header lines (first 5 lines; "--" in Lua, "//" in C, C++ and Rust):
#   targets: 5.5, 5.4    only these interpreters (default: all)
#   stdin: name.input    file fed on stdin
#   module               (Lua) library file loaded with require; not run itself
#   build: exe           (C/C++) compile against each interpreter's headers and
#                        static library to build/<id>/name, run, compare output
#   build: module        (C/C++) compile a Lua C module build/<id>/name.so;
#                        Lua examples in the same directory get
#                        LUA_CPATH=./build/<id>/?.so;;
#   build: shared        (C) plain shared library build/libname.so (for the FFI)
#
# Environment: LUA55, LUA54, LUAJIT (interpreters), CC, CXX, CARGO.
#   BLESS=1     write a missing name.expected from the first target's output
#   OVERRIDE=1  write name.<id>.expected where output differs from name.expected
# Usage: tests/run_all.sh [-v] [filter-substring]
set -u
cd "$(dirname "$0")/.."
ROOT=$PWD

VERBOSE=0
if [[ "${1:-}" == "-v" ]]; then VERBOSE=1; shift; fi
FILTER="${1:-}"
BLESS=${BLESS:-0}; OVERRIDE=${OVERRIDE:-0}
CC=${CC:-gcc}; CXX=${CXX:-g++}; CARGO=${CARGO:-cargo}
WARN="-Wall -Wextra -Werror"

declare -A BIN=( [5.5]="${LUA55:-lua5.5}" [5.4]="${LUA54:-lua5.4}" [jit]="${LUAJIT:-luajit}" )
declare -A FEATURE=( [5.5]=lua55 [5.4]=lua54 [jit]=luajit )
IDS=(5.5 5.4 jit)
LANGS=(lua c c++ rust)
declare -A PASS FAIL SKIP LPASS LFAIL LSKIP
for id in "${IDS[@]}"; do PASS[$id]=0; FAIL[$id]=0; SKIP[$id]=0; done
FAILURES=()

mkdir -p tests/results
VERS=tests/results/versions.txt
: > "$VERS"
declare -A INC LIBDIR LIBNAME
for id in "${IDS[@]}"; do
  if ! command -v "${BIN[$id]}" >/dev/null 2>&1; then
    echo "error: interpreter '${BIN[$id]}' ($id) not found" >&2; exit 2
  fi
  v=$("${BIN[$id]}" -v 2>&1 | head -1)
  echo "$id	$v" >> "$VERS"
  # headers and static library live next to the interpreter: PREFIX/bin/lua
  prefix=$(dirname "$(dirname "$(readlink -f "$(command -v "${BIN[$id]}")")")")
  if [[ $id == jit ]]; then
    INC[$id]=$prefix/include/luajit-2.1; LIBDIR[$id]=$prefix/lib; LIBNAME[$id]=luajit-5.1
  else
    INC[$id]=$prefix/include; LIBDIR[$id]=$prefix/lib; LIBNAME[$id]=lua
  fi
done

# per-lesson results: "lesson|id" -> count
declare -A LP LF LS NATIVE

header() {   # header FILE KEY -> value of "-- KEY: value" or "// KEY: value"
  head -5 "$1" | sed -n "s#^\(--\|//\) *$2: *##p" | head -1
}
targets_of() {
  local t; t=$(header "$1" targets)
  if [[ -z "$t" ]]; then echo "5.5 5.4 jit"; else echo "$t" | tr ',' ' '; fi
}
matches() { [[ -z "$FILTER" || "$1" == *"$FILTER"* ]]; }
lesson_of() { local l=${1#examples/}; echo "${l%%/*}"; }

skip() {     # skip ID LESSON LANG
  SKIP[$1]=$(( SKIP[$1] + 1 )); LS["$2|$1"]=$(( ${LS["$2|$1"]:-0} + 1 ))
  LSKIP["$3|$1"]=$(( ${LSKIP["$3|$1"]:-0} + 1 ))
}
fail() {     # fail ID LESSON LANG REL MESSAGE
  FAIL[$1]=$(( FAIL[$1] + 1 )); LF["$2|$1"]=$(( ${LF["$2|$1"]:-0} + 1 ))
  LFAIL["$3|$1"]=$(( ${LFAIL["$3|$1"]:-0} + 1 ))
  FAILURES+=("[$1] $4 ($5)"); echo "FAIL [$1] $4 ($5)"
}
# check ID LESSON LANG REL EXPECTED_BASE TARGETS RC OUTFILE ERRFILE
check() {
  local id=$1 lesson=$2 lang=$3 rel=$4 base=$5 tg=$6 rc=$7 out=$8 err=$9
  local exp="$base.$id.expected"
  [[ -f "$exp" ]] || exp="$base.expected"
  if [[ ! -f "$base.expected" && $BLESS == 1 && $rc -eq 0 ]]; then
    local first; first=$(echo $tg | awk '{print $1}')
    if [[ $id == "$first" ]]; then cp "$out" "$base.expected"; echo "blessed $base.expected ($id)"; fi
  fi
  if [[ ! -f "$base.expected" ]]; then fail "$id" "$lesson" "$lang" "$rel" "no .expected"; return; fi
  if [[ $rc -eq 0 && $OVERRIDE == 1 && ! -f "$base.$id.expected" ]] && ! cmp -s "$base.expected" "$out"; then
    cp "$out" "$base.$id.expected"; exp="$base.$id.expected"; echo "override $exp"
  fi
  if [[ $rc -eq 0 ]] && diff -u "$exp" "$out" > /tmp/lua-test-diff 2>&1; then
    PASS[$id]=$(( PASS[$id] + 1 )); LP["$lesson|$id"]=$(( ${LP["$lesson|$id"]:-0} + 1 ))
    LPASS["$lang|$id"]=$(( ${LPASS["$lang|$id"]:-0} + 1 ))
    [[ $VERBOSE -eq 1 ]] && echo "PASS [$id] $rel"
  else
    fail "$id" "$lesson" "$lang" "$rel" "exit $rc"
    sed 's/^/    /' /tmp/lua-test-diff | head -30
    sed 's/^/    stderr: /' "$err" | head -10
  fi
  return 0
}
TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT

# ---------------------------------------------------------------- C and C++
while IFS= read -r rel; do
  kind=$(header "$rel" build); [[ -z "$kind" ]] && continue
  dir=$(dirname "$rel"); file=$(basename "$rel"); base=${file%.*}; lesson=$(lesson_of "$rel")
  NATIVE[$lesson]=1
  if [[ $rel == *.cpp ]]; then lang=c++; comp="$CXX -std=c++17"; else lang=c; comp="$CC -std=c11"; fi
  tg=" $(targets_of "$rel") "
  case $kind in
    shared)
      mkdir -p "$dir/build"
      if ! $comp -O2 $WARN -shared -fPIC -o "$dir/build/lib$base.so" "$rel" 2> "$TMPD/err"; then
        FAILURES+=("$rel (build)"); echo "BUILD FAIL $rel"; sed 's/^/    /' "$TMPD/err" | head -20
      fi ;;
    module)
      for id in "${IDS[@]}"; do
        [[ "$tg" == *" $id "* ]] || continue
        mkdir -p "$dir/build/$id"
        if ! $comp -O2 $WARN -shared -fPIC -I"${INC[$id]}" -o "$dir/build/$id/$base.so" "$rel" 2> "$TMPD/err"; then
          fail "$id" "$lesson" "$lang" "$rel" "build"; sed 's/^/    /' "$TMPD/err" | head -20
        fi
      done ;;
    exe)
      matches "$rel" || continue
      stdin_file=$(header "$rel" stdin)
      for id in "${IDS[@]}"; do
        if [[ "$tg" != *" $id "* ]]; then skip "$id" "$lesson" "$lang"; continue; fi
        mkdir -p "$dir/build/$id"
        if ! $comp -O2 $WARN -I"${INC[$id]}" -o "$dir/build/$id/$base" "$rel" \
             "${LIBDIR[$id]}/lib${LIBNAME[$id]}.a" -lm -ldl -Wl,-E 2> "$TMPD/err"; then
          fail "$id" "$lesson" "$lang" "$rel" "build"; sed 's/^/    /' "$TMPD/err" | head -20; continue
        fi
        (cd "$dir" && timeout 20 "./build/$id/$base" < "${stdin_file:-/dev/null}") > "$TMPD/out" 2> "$TMPD/err"; rc=$?
        check "$id" "$lesson" "$lang" "$rel" "$dir/$base" "$tg" $rc "$TMPD/out" "$TMPD/err"
      done ;;
    *) FAILURES+=("$rel (unknown build kind '$kind')") ;;
  esac
done < <(find examples \( -name build -o -name target \) -prune -o \( -name '*.c' -o -name '*.cpp' \) -print | sort)

# ---------------------------------------------------------------- Lua
while IFS= read -r rel; do
  matches "$rel" || continue
  if head -5 "$rel" | grep -q '^-- *module *$'; then continue; fi
  dir=$(dirname "$rel"); base=$(basename "$rel" .lua); lesson=$(lesson_of "$rel")
  tg=" $(targets_of "$rel") "
  stdin_file=$(header "$rel" stdin)
  for id in "${IDS[@]}"; do
    if [[ "$tg" != *" $id "* ]]; then skip "$id" "$lesson" lua; continue; fi
    (cd "$dir" && env -u LUA_CPATH_5_5 -u LUA_CPATH_5_4 -u LUA_PATH -u LUA_PATH_5_5 -u LUA_PATH_5_4 \
       -u LUA_INIT -u LUA_INIT_5_5 -u LUA_INIT_5_4 LUA_CPATH="./build/$id/?.so;;" \
       timeout 20 "${BIN[$id]}" "$base.lua" < "${stdin_file:-/dev/null}") > "$TMPD/out" 2> "$TMPD/err"; rc=$?
    check "$id" "$lesson" lua "$rel" "$dir/$base" "$tg" $rc "$TMPD/out" "$TMPD/err"
  done
done < <(find examples \( -name build -o -name target \) -prune -o -name '*.lua' -print | sort)

# ---------------------------------------------------------------- Rust
while IFS= read -r toml; do
  crate=$(dirname "$toml"); lesson=$(lesson_of "$crate")
  bins=$(ls "$crate"/src/bin/*.rs 2>/dev/null | sort)
  want=0; for b in $bins; do matches "$b" && want=1; done
  [[ $want -eq 1 ]] || continue
  NATIVE[$lesson]=1
  if ! command -v "$CARGO" >/dev/null 2>&1; then
    FAILURES+=("$crate (cargo not found)"); echo "FAIL $crate: cargo not found"; continue
  fi
  for id in "${IDS[@]}"; do
    any=0; for b in $bins; do [[ " $(targets_of "$b") " == *" $id "* ]] && any=1; done
    built=0
    if [[ $any -eq 1 ]]; then
      if (cd "$crate" && LUA_LIB="${LIBDIR[$id]}" LUA_LIB_NAME="${LIBNAME[$id]}" LUA_LINK=static \
            "$CARGO" build --release --locked --quiet --no-default-features \
            --features "${FEATURE[$id]}" --target-dir "target/$id") > "$TMPD/err" 2>&1; then built=1
      else echo "CARGO BUILD FAIL [$id] $crate"; sed 's/^/    /' "$TMPD/err" | tail -30; fi
    fi
    for b in $bins; do
      matches "$b" || continue
      name=$(basename "$b" .rs); tg=" $(targets_of "$b") "
      if [[ "$tg" != *" $id "* ]]; then skip "$id" "$lesson" rust; continue; fi
      if [[ $built -eq 0 ]]; then fail "$id" "$lesson" rust "$b" "cargo build"; continue; fi
      stdin_file=$(header "$b" stdin)
      (cd "$crate" && timeout 20 "./target/$id/release/$name" < "${stdin_file:-/dev/null}") > "$TMPD/out" 2> "$TMPD/err"; rc=$?
      check "$id" "$lesson" rust "$b" "${b%.rs}" "$tg" $rc "$TMPD/out" "$TMPD/err"
    done
  done
done < <(find examples -maxdepth 2 -name Cargo.toml | sort)

# Badge snippets: one per lesson, listing only the interpreters on which
# every applicable example passed.
mkdir -p includes/badges
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
      if [[ -n "${NATIVE[$lesson]:-}" ]]; then
        printf '    C, C++ and Rust examples are compiled against each interpreter'"'"'s own headers\n'
        printf '    and static library, then run the same way.\n'
      fi
    } > "includes/badges/$lesson.md"
  done
fi

echo
echo "Interpreters:"; sed 's/^/  /' "$VERS"
echo
printf '%-6s %6s %6s %6s\n' interp pass fail skip
for id in "${IDS[@]}"; do printf '%-6s %6d %6d %6d\n' "$id" "${PASS[$id]}" "${FAIL[$id]}" "${SKIP[$id]}"; done
echo
printf '%-6s' lang; for id in "${IDS[@]}"; do printf ' %16s' "$id pass/fail/skip"; done; echo
for lang in "${LANGS[@]}"; do
  printf '%-6s' "$lang"
  for id in "${IDS[@]}"; do
    printf ' %16s' "${LPASS["$lang|$id"]:-0}/${LFAIL["$lang|$id"]:-0}/${LSKIP["$lang|$id"]:-0}"
  done; echo
done
if [[ ${#FAILURES[@]} -gt 0 ]]; then
  echo; echo "Failures:"; printf '  %s\n' "${FAILURES[@]}"; exit 1
fi
echo; echo "All examples passed."
