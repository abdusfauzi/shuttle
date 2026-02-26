#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/apple-scripts/terminal"
OUTPUT_DIR="$ROOT_DIR/Shuttle/apple-scpt"
COMMON_LIB="$ROOT_DIR/apple-scripts/lib/compile-common.sh"

source "$COMMON_LIB"

mkdir -p "$OUTPUT_DIR"

echo "Compiling AppleScripts for Terminal.app..."
compile_script "$OUTPUT_DIR/terminal-new-window.scpt" "$SOURCE_DIR/terminal-new-window.applescript"
compile_script "$OUTPUT_DIR/terminal-current-window.scpt" "$SOURCE_DIR/terminal-current-window.applescript"
compile_script "$OUTPUT_DIR/terminal-new-tab-default.scpt" "$SOURCE_DIR/terminal-new-tab-default.applescript"
