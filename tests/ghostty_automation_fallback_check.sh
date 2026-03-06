#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/Shuttle/AppServices.swift"

if ! /usr/bin/grep -q 'runGhosttyDirect' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty direct-launch fallback helper is missing." >&2
    exit 1
fi

if ! /usr/bin/grep -q 'isGhosttyPermissionFailure' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty permission-failure matcher is missing." >&2
    exit 1
fi

if ! /usr/bin/grep -q 'request.mode == .new && isGhosttyPermissionFailure(info)' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty direct fallback is not limited to new-window mode." >&2
    exit 1
fi

if ! /usr/bin/grep -q 'not authorized to send apple events to system events' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty AppleEvents authorization fallback trigger is missing." >&2
    exit 1
fi

if ! /usr/bin/grep -q 'not allowed to send keystrokes' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty keystroke permission fallback trigger is missing." >&2
    exit 1
fi

if ! /usr/bin/grep -q 'runningApplications(withBundleIdentifier: "com.mitchellh.ghostty")' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty direct launch does not detect a running app instance." >&2
    exit 1
fi

if ! /usr/bin/grep -q '"-n", "-a", "Ghostty"' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty direct launch does not force a fresh launch when Ghostty is already running." >&2
    exit 1
fi

if ! /usr/bin/grep -F -q 'let ghosttyCommandArgument = "--command=shell:\(command)"' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty direct launch does not use Ghostty shell-command mode." >&2
    exit 1
fi

echo "OK: Ghostty has AppleEvents authorization fallback to direct launch."
