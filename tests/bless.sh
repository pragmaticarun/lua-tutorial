#!/usr/bin/env bash
# Authoring helper: create missing .expected files from each example's FIRST
# target interpreter (Lua, C, C++ and Rust). ALWAYS review the generated output
# by hand before committing; run_all.sh is the real test.
# Usage: tests/bless.sh [filter-substring]
cd "$(dirname "$0")/.." && BLESS=1 exec tests/run_all.sh "$@"
