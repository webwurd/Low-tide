#!/usr/bin/env bash
# Runs every test suite that can run outside the Unity editor. Exit code 0 only if ALL pass:
#   1. Godot headless suite (the reference build)
#   2. Fixtures are fresh (re-export from Godot, must be byte-identical to what is checked in)
#   3. C# core parity tests (dotnet) if a .NET SDK is installed
# Usage: GODOT=/path/to/godot tools/run_all_tests.sh
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
export GODOT
fail=0

echo "== 1/3 Godot suite"
tools/run_tests.sh || fail=1

echo "== 2/3 fixtures up to date"
tmp="$(mktemp -d)"
cp unity/Fixtures/*.json "$tmp"/
"$GODOT" --headless -s tools/export_fixtures.gd >/dev/null 2>&1
if diff -rq "$tmp" unity/Fixtures >/dev/null; then echo "fixtures: up to date"
else echo "FIXTURES WERE STALE (now regenerated; review and commit unity/Fixtures)"; diff -rq "$tmp" unity/Fixtures; fail=1; fi
rm -rf "$tmp"

echo "== 3/3 C# core parity"
if command -v dotnet >/dev/null 2>&1; then
  DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 dotnet test unity/dotnet/Tests/LowTide.Core.Tests.csproj 2>&1 | grep -E "Passed!|Failed|error" || fail=1
  [ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
else
  echo "dotnet not installed: C# tests NOT run"; fail=1
fi

if [ $fail -eq 0 ]; then echo "ALL TESTS PASSED"; else echo "SOME TESTS FAILED"; fi
exit $fail
