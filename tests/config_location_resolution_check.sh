#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/Shuttle/AppServices.swift"

grep -q "SelectedConfigBookmark" "$SOURCE" || {
    echo "FAIL: bookmark persistence key missing" >&2
    exit 1
}

grep -q "\\.shuttle.path" "$SOURCE" || {
    echo "FAIL: compatibility path file handling missing" >&2
    exit 1
}

grep -q "resolvingBookmarkData:" "$SOURCE" || {
    echo "FAIL: bookmark resolution missing" >&2
    exit 1
}

grep -q "bookmarkData(" "$SOURCE" || {
    echo "FAIL: bookmark save missing" >&2
    exit 1
}

grep -q "resolveConfigLocation()" "$SOURCE" || {
    echo "FAIL: config location resolver missing" >&2
    exit 1
}

grep -q "saveSelectedConfigFile" "$SOURCE" || {
    echo "FAIL: selected config save path missing" >&2
    exit 1
}

grep -q "clearSelectedConfigFile" "$SOURCE" || {
    echo "FAIL: selected config reset missing" >&2
    exit 1
}

echo "OK: config location bookmark resolution wiring present."
