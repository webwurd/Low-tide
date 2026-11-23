#!/usr/bin/env bash
# Runs the headless suite. Exits non-zero unless it reports "N checks, 0 failures".
# Usage: GODOT=/path/to/godot tools/run_tests.sh
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --import >/dev/null 2>&1
LOG="${TMPDIR:-/tmp}/lowtide_tests.log"
"$GODOT" --headless -s tests/run_tests.gd >"$LOG" 2>&1
rc=$?
grep -E "FAIL|SCRIPT ERROR|checks," "$LOG"
if [ $rc -ne 0 ]; then echo "TESTS FAILED (exit $rc)"; exit $rc; fi
if ! grep -qE "[0-9]+ checks, 0 failures" "$LOG"; then echo "TESTS FAILED (no clean summary line)"; exit 1; fi
echo "TESTS PASSED"
