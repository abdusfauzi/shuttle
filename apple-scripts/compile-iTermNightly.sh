#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/apple-scripts/iTermNightly"
OUTPUT_DIR="$ROOT_DIR/Shuttle/apple-scpt"
COMMON_LIB="$ROOT_DIR/apple-scripts/lib/compile-common.sh"

source "$COMMON_LIB"

mkdir -p "$OUTPUT_DIR"

echo "Compiling AppleScripts for iTerm nightly..."
compile_script "$OUTPUT_DIR/iTerm2-nightly-new-window.scpt" "$SOURCE_DIR/iTerm2-nightly-new-window.applescript"
compile_script "$OUTPUT_DIR/iTerm2-nightly-current-window.scpt" "$SOURCE_DIR/iTerm2-nightly-current-window.applescript"
compile_script "$OUTPUT_DIR/iTerm2-nightly-new-tab-default.scpt" "$SOURCE_DIR/iTerm2-nightly-new-tab-default.applescript"
