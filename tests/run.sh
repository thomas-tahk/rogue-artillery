#!/usr/bin/env bash
# Run the headless test suite. Fails on any failed check OR any script error.
# Usage: GODOT=/path/to/godot tests/run.sh
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . --import >/dev/null 2>&1
out=$(timeout 300 "$GODOT" --headless --path . --fixed-fps 60 -s res://tests/run_tests.gd 2>&1)
code=$?
echo "$out"
if [ $code -ne 0 ]; then exit $code; fi
if grep -qE "SCRIPT ERROR|Parse Error|Failed to load script" <<<"$out"; then
  echo "FAILED: script errors in output"; exit 1
fi
