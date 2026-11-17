#!/usr/bin/env bash
# Authoring helper: for the given example files, write NAME.<id>.expected for
# every target interpreter whose stdout differs from NAME.expected.
# Use ONLY for intentional, documented version differences, and review them.
# Usage: tests/bless_overrides.sh examples/NN-slug/file.lua [more files...]
cd "$(dirname "$0")/.."
rc=0
for f in "$@"; do OVERRIDE=1 tests/run_all.sh "$f" | grep -E '^(override|FAIL)' || true; done
exit $rc
