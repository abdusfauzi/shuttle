#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/apple-scripts/Warp"
OUTPUT_DIR="$ROOT_DIR/Shuttle/apple-scpt"
COMMON_LIB="$ROOT_DIR/apple-scripts/lib/compile-common.sh"

source "$COMMON_LIB"

mkdir -p "$OUTPUT_DIR"

echo "Compiling AppleScripts for Warp (legacy helpers)..."
compile_script "$OUTPUT_DIR/Warp-stable-new-window.scpt" "$SOURCE_DIR/Warp-stable-new-window.applescript"
compile_script "$OUTPUT_DIR/Warp-stable-current-window.scpt" "$SOURCE_DIR/Warp-stable-current-window.applescript"
compile_script "$OUTPUT_DIR/Warp-stable-new-tab-default.scpt" "$SOURCE_DIR/Warp-stable-new-tab-default.applescript"
