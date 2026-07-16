#!/usr/bin/env bash
# Project CogGrid — headless test runner.
#
# Runs every SceneTree test suite under a headless Godot 4 build and reports a
# combined pass/fail. Each suite calls quit(0) on success and quit(1) on
# failure, so the process exit code is what we aggregate.
#
# Godot executable resolution order:
#   1. $GODOT_BIN (explicit override)
#   2. the first of godot / godot4 / Godot / godot-headless found on PATH
#
# Usage:
#   ./run_tests.sh                # run all suites
#   GODOT_BIN=/path/to/godot ./run_tests.sh
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_godot() {
	if [ -n "${GODOT_BIN:-}" ]; then
		command -v "${GODOT_BIN}" 2>/dev/null || printf '%s\n' "${GODOT_BIN}"
		return 0
	fi
	local cand
	for cand in godot godot4 Godot godot-headless; do
		if command -v "$cand" >/dev/null 2>&1; then
			command -v "$cand"
			return 0
		fi
	done
	return 1
}

GODOT="$(resolve_godot)" || {
	echo "ERROR: Godot 4 executable not found." >&2
	echo "       Set GODOT_BIN=/path/to/godot or add a 'godot' binary to PATH." >&2
	exit 127
}

echo "Godot: $GODOT"
"$GODOT" --version 2>/dev/null || true
echo

SUITES=(
	"res://tests/test_battle.gd"
	"res://tests/test_rpg.gd"
	"res://tests/test_flow.gd"
)

failures=0
for suite in "${SUITES[@]}"; do
	echo "── $suite ──────────────────────────────"
	if "$GODOT" --headless --path "$PROJECT_DIR" --script "$suite"; then
		echo "  PASS  $suite"
	else
		rc=$?
		echo "  FAIL  $suite (exit $rc)" >&2
		failures=$((failures + 1))
	fi
	echo
done

if [ "$failures" -eq 0 ]; then
	echo "ALL SUITES PASSED (${#SUITES[@]}/${#SUITES[@]})"
	exit 0
fi

echo "$failures/${#SUITES[@]} SUITE(S) FAILED" >&2
exit 1
