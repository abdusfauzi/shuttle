#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

target="$(xcodebuild -project "$ROOT_DIR/Shuttle.xcodeproj" -scheme Shuttle -configuration Release -showBuildSettings | awk -F' = ' '/^[[:space:]]*MACOSX_DEPLOYMENT_TARGET = / {print $2; exit}')"

if [[ "$target" != "13.0" ]]; then
    echo "FAIL: expected MACOSX_DEPLOYMENT_TARGET=13.0, got $target" >&2
    exit 1
fi

echo "OK: deployment target is pinned to macOS 13.0."
