#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/Shuttle/AppServices.swift"

if ! /usr/bin/grep -q 'runGhosttyDirect' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty direct-launch fallback helper is missing." >&2
    exit 1
fi

if ! /usr/bin/grep -q 'Not authorized to send Apple events to System Events' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty AppleEvents authorization fallback trigger is missing." >&2
    exit 1
fi

if ! /usr/bin/grep -q 'openTask.arguments = \["-a", "Ghostty", "--args", "-e", "/bin/zsh", "-lc", command\]' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty direct launch does not use safe shell argument form." >&2
    exit 1
fi

echo "OK: Ghostty has AppleEvents authorization fallback to direct launch."
