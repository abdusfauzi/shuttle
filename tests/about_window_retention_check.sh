#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/Shuttle/AppDelegate.swift"

if ! /usr/bin/grep -q "private var aboutWindowController: AboutWindowController\?" "$SOURCE"; then
    echo "FAIL: About window controller is not retained." >&2
    exit 1
fi

if ! /usr/bin/grep -q "aboutWindowController = AboutWindowController" "$SOURCE"; then
    echo "FAIL: showAbout does not assign retained controller instance." >&2
    exit 1
fi

echo "OK: About window controller retention guard passed."
