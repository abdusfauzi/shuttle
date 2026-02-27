#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/Shuttle/AppServices.swift"

if /usr/bin/grep -q '"-na", "Ghostty.app"' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty launch still uses 'open -na', which can spawn extra windows/instances." >&2
    exit 1
fi

if ! /usr/bin/grep -q 'services.runUIControlledTerminal("Ghostty", request.command, request.mode.rawValue)' "$SOURCE_FILE"; then
    echo "FAIL: Ghostty backend is not routed through UI-controlled launch path." >&2
    exit 1
fi

echo "OK: Ghostty launch policy uses UI-controlled terminal routing."
