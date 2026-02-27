#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/Shuttle/apple-scpt"

"$ROOT_DIR/apple-scripts/compile-WarpStable.sh"

required_outputs=(
    "Warp-stable-new-window.scpt"
    "Warp-stable-current-window.scpt"
    "Warp-stable-new-tab-default.scpt"
)

for filename in "${required_outputs[@]}"; do
    if [[ ! -f "$OUTPUT_DIR/$filename" ]]; then
        echo "FAIL: missing compiled legacy Warp script: Shuttle/apple-scpt/$filename" >&2
        exit 1
    fi
done

echo "OK: legacy Warp AppleScript helpers compile successfully."
