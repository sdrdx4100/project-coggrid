#!/bin/bash
# SessionStart hook for Project CogGrid (Godot 4).
#
# The test suites run under a headless Godot 4 binary. This hook locates such a
# binary and exports GODOT_BIN so ./run_tests.sh and the agent can run the
# suites without further setup.
#
# It never fails the session: Godot is a large external binary and some network
# policies block fetching it. If no Godot is present the hook reports how to
# provide one and exits 0, leaving the session fully usable for static work.
set -euo pipefail

find_godot() {
	if [ -n "${GODOT_BIN:-}" ] && command -v "${GODOT_BIN}" >/dev/null 2>&1; then
		command -v "${GODOT_BIN}"
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

if godot_bin="$(find_godot)"; then
	echo "[session-start] Godot found: $godot_bin"
	"$godot_bin" --version 2>/dev/null || true
	if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
		echo "export GODOT_BIN=\"$godot_bin\"" >> "$CLAUDE_ENV_FILE"
		echo "[session-start] Exported GODOT_BIN for this session."
	fi
	echo "[session-start] Run the suites with: ./run_tests.sh"
else
	echo "[session-start] Godot 4 executable not found on PATH."
	echo "[session-start] Install Godot 4.7.1 Standard (or set GODOT_BIN) to run ./run_tests.sh."
	echo "[session-start] Static review and edits work without it; only test execution needs Godot."
fi

exit 0
