#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/Shuttle/LaunchAtLoginController.swift"

if /usr/bin/grep -q "kLSSharedFileListItemBeforeFirst\.takeUnretainedValue()" "$SOURCE_FILE"; then
    echo "FAIL: unsafe kLSSharedFileListItemBeforeFirst.takeUnretainedValue() usage detected." >&2
    echo "This can crash on modern macOS when launch-at-login is enabled." >&2
    exit 1
fi

echo "OK: no unsafe LSSharedFileList sentinel conversion detected."
