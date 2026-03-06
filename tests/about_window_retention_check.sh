#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/Shuttle/AppDelegate.swift"

if ! /usr/bin/grep -q "private var settingsWindowController: SettingsWindowController\?" "$SOURCE"; then
    echo "FAIL: Settings window controller is not retained." >&2
    exit 1
fi

if ! /usr/bin/grep -q "settingsWindowController = controller" "$SOURCE"; then
    echo "FAIL: showSettings does not assign retained controller instance." >&2
    exit 1
fi

echo "OK: Settings window controller retention guard passed."
