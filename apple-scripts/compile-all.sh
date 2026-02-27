#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Compiling Shuttle AppleScripts into Shuttle/apple-scpt..."
"$ROOT_DIR/apple-scripts/compile-Terminal.sh"
"$ROOT_DIR/apple-scripts/compile-iTermStable.sh"
"$ROOT_DIR/apple-scripts/compile-iTermNightly.sh"
"$ROOT_DIR/apple-scripts/compile-Virtual.sh"

if [[ "${INCLUDE_LEGACY_WARP_COMPILE:-0}" == "1" ]]; then
    "$ROOT_DIR/apple-scripts/compile-WarpStable.sh"
else
    echo "Skipping Warp legacy helper compilation (deprecated; set INCLUDE_LEGACY_WARP_COMPILE=1 to include)."
fi

echo "Done."
