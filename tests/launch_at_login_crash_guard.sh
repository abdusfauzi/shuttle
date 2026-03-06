#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/Shuttle/LaunchAtLoginController.swift"

if /usr/bin/grep -q "unsafeBitCast" "$SOURCE_FILE"; then
    echo "FAIL: unsafeBitCast usage detected in launch-at-login controller." >&2
    echo "Avoid unsafe conversions in legacy launch-at-login flow." >&2
    exit 1
fi

if /usr/bin/grep -q "kLSSharedFileListItemBeforeFirst" "$SOURCE_FILE" &&
   /usr/bin/grep -q "toOpaque()" "$SOURCE_FILE"; then
    echo "FAIL: legacy LSSharedFileList before-first sentinel converted through toOpaque()." >&2
    echo "Use LSSharedFileListItem before-first via managed conversion without toOpaque()." >&2
    exit 1
fi

echo "OK: no unsafe LSSharedFileList sentinel conversion detected."
